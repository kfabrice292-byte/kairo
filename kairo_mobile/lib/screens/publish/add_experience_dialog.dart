import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class AddExperienceDialog extends StatefulWidget {
  const AddExperienceDialog({super.key});

  @override
  State<AddExperienceDialog> createState() => _AddExperienceDialogState();
}

class _AddExperienceDialogState extends State<AddExperienceDialog> {
  final _titleController = TextEditingController();
  final _orgController = TextEditingController();
  final _periodController = TextEditingController();
  final _descController = TextEditingController();
  final _skillsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _orgController.dispose();
    _periodController.dispose();
    _descController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _orgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre et l\'organisation sont requis.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;

    if (user != null) {
      final newExp = Experience(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        organization: _orgController.text.trim(),
        period: _periodController.text.trim(),
        description: _descController.text.trim(),
        skillsUsed: _skillsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      final updatedExperiences = List<Experience>.from(user.experiences)
        ..insert(0, newExp);

      try {
        await auth.updateProfile({
          'experiences': updatedExperiences.map((e) => e.toMap()).toList(),
        });

        // Bonus: on pourrait créer un post "A commencé une nouvelle expérience" ici
        // pour que ça apparaisse dans le feed d'actualité.

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expérience ajoutée !'),
              backgroundColor: Colors.green,
            ),
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
                  Text(
                    'Ajouter une expérience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KairoTextField(
                controller: _titleController,
                hintText: 'Titre du poste',
                prefixIcon: PhosphorIcons.briefcase(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _orgController,
                hintText: 'Entreprise / Organisation',
                prefixIcon: PhosphorIcons.buildings(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _periodController,
                hintText: 'Période (ex: Jan 2023 - Présent)',
                prefixIcon: PhosphorIcons.calendar(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Description des missions...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _skillsController,
                hintText: 'Compétences (séparées par une virgule)',
                prefixIcon: PhosphorIcons.lightning(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).cardColor,
                        ),
                      )
                    : Text(
                        'Sauvegarder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
