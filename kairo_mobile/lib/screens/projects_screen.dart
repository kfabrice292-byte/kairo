import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/project_provider.dart';
import '../core/models/project_model.dart';
import '../core/providers/auth_provider.dart';

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
      // Le FAB universel de MainScaffold permet déjà de créer un projet, 
      // mais on peut laisser un raccourci ici ou le retirer. 
      // Puisque l'utilisateur a son FAB universel, on retire celui-ci.
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userModel?.uid;
    final isFounder = currentUserId == project.founderId;
    final isMember = project.members.contains(currentUserId);
    final hasRequested = project.joinRequests.contains(currentUserId);

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
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: project.founderPhoto.isNotEmpty ? NetworkImage(project.founderPhoto) : null,
                  child: project.founderPhoto.isEmpty ? const Icon(Icons.person, size: 12, color: Colors.grey) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  project.founderName,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.description,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (project.goals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Objectifs :', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(project.goals, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(PhosphorIcons.users(), size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('${project.members.length} / ${project.maxParticipants} membres', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                if (project.estimatedDuration.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(PhosphorIcons.hourglass(), size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(project.estimatedDuration, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ]
              ],
            ),
            const SizedBox(height: 20),
            if (project.skillsRequired.isNotEmpty) ...[
              Text(
                'Compétences recherchées :',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.skillsRequired.map((role) => _RoleBadge(role: role)).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/chat_detail', extra: {
                        'userId': project.founderId,
                        'userName': project.founderName,
                      });
                    },
                    icon: Icon(PhosphorIcons.chatCircleText(), size: 18),
                    label: const Text('Contacter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isFounder || isMember || hasRequested
                        ? null
                        : () async {
                            await context.read<ProjectProvider>().requestToJoin(project.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande envoyée !'), backgroundColor: Colors.green),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                    ),
                    child: Text(
                      isFounder ? 'Mon projet' : (isMember ? 'Membre' : (hasRequested ? 'En attente' : 'Rejoindre')),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
