import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../core/providers/project_provider.dart';
import '../core/models/project_model.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/kairo_text_field.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Projets', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final projects = provider.projects;
          
          if (provider.isLoading && projects.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
          }

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.rocketLaunch(PhosphorIconsStyle.light), size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Aucun projet en cours', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _ProjectCard(project: projects[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _CreateProjectDialog(),
          );
        },
        backgroundColor: const Color(0xFFF97316),
        icon: Icon(PhosphorIcons.plus(), color: Colors.white),
        label: const Text('Lancer un projet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (project.isOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Recrute',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Par ${project.founderName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              project.description,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            if (project.seekingRoles.isNotEmpty) ...[
              Text(
                'Profils recherchés :',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.seekingRoles.map((role) => _RoleBadge(role: role)).toList(),
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFF97316)),
                  foregroundColor: const Color(0xFFF97316),
                ),
                child: const Text('Voir le projet', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        role,
        style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rolesController = TextEditingController();
  bool _isPublishing = false;

  Future<void> _publish() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) return;

    setState(() => _isPublishing = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userData;
      final founderName = user?['name'] ?? 'Utilisateur';

      final roles = _rolesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final project = ProjectModel(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        founderId: 'temp_id', // Replaced by server ideally
        founderName: founderName,
        isOpen: true,
        seekingRoles: roles,
        createdAt: DateTime.now(),
      );

      await context.read<ProjectProvider>().addProject(project);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projet lancé avec succès !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lancer un projet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KairoTextField(
                controller: _titleController,
                hintText: 'Titre du projet',
                prefixIcon: PhosphorIcons.rocketLaunch(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _descriptionController,
                hintText: 'Description (Quelle est votre idée ?)',
                prefixIcon: PhosphorIcons.textAa(),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _rolesController,
                hintText: 'Profils (ex: Développeur, Designer)',
                prefixIcon: PhosphorIcons.users(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isPublishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isPublishing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lancer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
