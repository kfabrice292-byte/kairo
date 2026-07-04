import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/project_model.dart';
import '../../widgets/kairo_text_field.dart';

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _goalsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _durationController = TextEditingController();
  final _participantsController = TextEditingController(text: "5");
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _goalsController.dispose();
    _skillsController.dispose();
    _durationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre et la description sont requis.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;

    if (user != null) {
      final newProject = ProjectModel(
        id: '', // Firestore generera l'ID
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        goals: _goalsController.text.trim(),
        founderId: user.uid,
        founderName: user.name.isNotEmpty ? user.name : 'Utilisateur',
        founderPhoto: user.photoURL,
        skillsRequired: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        maxParticipants: int.tryParse(_participantsController.text) ?? 5,
        estimatedDuration: _durationController.text.trim(),
        members: [user.uid], // Le fondateur est membre de base
        createdAt: DateTime.now(),
      );

      try {
        final docRef = await FirebaseFirestore.instance.collection('projects').add(newProject.toMap());
        
        // Ajouter le projet au profil (enrichissement auto)
        final updatedProjects = List<String>.from(user.projectIds)..add(docRef.id);
        await auth.updateProfile({'projectIds': updatedProjects});

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Projet publié !'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Créer un projet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KairoTextField(controller: _titleController, hintText: 'Nom du projet', prefixIcon: PhosphorIcons.rocketLaunch()),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Description détaillée...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              KairoTextField(controller: _goalsController, hintText: 'Objectifs du projet', prefixIcon: PhosphorIcons.target()),
              const SizedBox(height: 12),
              KairoTextField(controller: _skillsController, hintText: 'Compétences recherchées (ex: UI, Flutter)', prefixIcon: PhosphorIcons.lightning()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: KairoTextField(controller: _durationController, hintText: 'Durée (ex: 2 mois)', prefixIcon: PhosphorIcons.hourglass())),
                  const SizedBox(width: 8),
                  Expanded(child: KairoTextField(controller: _participantsController, hintText: 'Max. Membres', prefixIcon: PhosphorIcons.users())),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Publier le projet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
