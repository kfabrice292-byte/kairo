import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/project_model.dart';
import '../core/providers/project_provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _taskTitleController = TextEditingController();

  @override
  void dispose() {
    _taskTitleController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nouvelle tâche'),
          content: TextField(
            controller: _taskTitleController,
            decoration: const InputDecoration(hintText: 'Titre de la tâche'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _taskTitleController.text.trim();
                if (title.isNotEmpty) {
                  final newTask = {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title,
                    'status': 'todo',
                    'assignedTo': '',
                  };
                  context.read<ProjectProvider>().addTask(
                    widget.project.id,
                    newTask,
                  );
                }
                Navigator.pop(context);
                _taskTitleController.clear();
              },
              child: Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // We watch the provider to get real-time updates (especially tasks and members)
    final project = context.watch<ProjectProvider>().projects.firstWhere(
      (p) => p.id == widget.project.id,
      orElse: () => widget.project,
    );

    final isFounder = currentUserId == project.founderId;
    final isMember = project.members.contains(currentUserId);
    final hasRequested = project.joinRequests.contains(currentUserId);
    final isCollaborator = isFounder || isMember;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
          title: Text(
            project.title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Détails'),
              Tab(text: 'Kanban'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(
              project,
              currentUserId,
              isFounder,
              isMember,
              hasRequested,
            ),
            _buildKanbanTab(project, isCollaborator, isFounder),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(
    ProjectModel project,
    String? currentUserId,
    bool isFounder,
    bool isMember,
    bool hasRequested,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: project.status == 'in_progress'
                  ? Colors.blue.shade50
                  : (project.status == 'completed'
                        ? Colors.green.shade50
                        : Colors.purple.shade50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              project.status == 'in_progress'
                  ? 'En cours'
                  : (project.status == 'completed' ? 'Terminé' : 'Idéation'),
              style: TextStyle(
                color: project.status == 'in_progress'
                    ? Colors.blue
                    : (project.status == 'completed'
                          ? Colors.green
                          : Colors.purple),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
          ),
          const SizedBox(height: 24),

          if (project.goals.isNotEmpty) ...[
            Text(
              'Objectifs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              project.goals,
              style: TextStyle(color: Colors.grey.shade800, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Membres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMemberRow(project.founderName, true),
          ...project.members.map(
            (mId) => _buildFutureMemberRow(mId, false),
          ),
          const SizedBox(height: 24),
          
          if (isFounder && project.joinRequests.isNotEmpty) ...[
            Text(
              'Demandes en attente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 12),
            ...project.joinRequests.map(
              (reqId) => _buildJoinRequestRow(reqId, project.id, context),
            ),
            const SizedBox(height: 24),
          ],

          if (project.externalLinks.isNotEmpty) ...[
            Text(
              'Liens utiles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...project.externalLinks.map(
              (link) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link, color: AppColors.primary),
                title: Text(
                  link,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () => _launchUrl(link),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (!isFounder && !isMember && project.isOpen) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: hasRequested
                  ? null
                  : () async {
                      await context.read<ProjectProvider>().requestToJoin(
                        project.id,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demande envoyée !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                hasRequested ? 'Demande en attente' : 'Rejoindre le projet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).cardColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberRow(String name, bool isFounder, {String? avatarUrl}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isFounder
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty ? Icon(
              PhosphorIcons.user(),
              color: isFounder ? AppColors.primary : Colors.grey.shade600,
            ) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FutureBuilder<DocumentSnapshot?>(
                  future: FirebaseFirestore.instance.collection('users').where('name', isEqualTo: name).limit(1).get().then((value) => value.docs.firstOrNull),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      if (data['isVerified'] == true) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                            color: AppColors.primary,
                            size: 16,
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          if (isFounder) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Fondateur',
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFutureMemberRow(String userId, bool isFounder) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildMemberRow('Utilisateur inconnu', isFounder);
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Utilisateur';
        final photoUrl = data['photoURL'] as String?;
        return _buildMemberRow(name, isFounder, avatarUrl: photoUrl);
      },
    );
  }

  Widget _buildJoinRequestRow(String userId, String projectId, BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Utilisateur';
        final photoUrl = data['photoURL'] as String?;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty ? Icon(
                  PhosphorIcons.user(),
                  color: Colors.grey.shade600,
                ) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => context.read<ProjectProvider>().acceptJoinRequest(projectId, userId),
              ),
              IconButton(
                icon: Icon(Icons.cancel, color: Colors.red),
                onPressed: () => context.read<ProjectProvider>().refuseJoinRequest(projectId, userId),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanTab(
    ProjectModel project,
    bool isCollaborator,
    bool isFounder,
  ) {
    final todoTasks = project.tasks
        .where((t) => t['status'] == 'todo')
        .toList();
    final inProgressTasks = project.tasks
        .where((t) => t['status'] == 'in_progress')
        .toList();
    final doneTasks = project.tasks
        .where((t) => t['status'] == 'done')
        .toList();

    return Column(
      children: [
        if (isFounder)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(context),
              icon: Icon(Icons.add),
              label: Text('Ajouter une tâche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                foregroundColor: AppColors.primary,
                elevation: 0,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildTaskSection(
                'À faire',
                todoTasks,
                'todo',
                project.id,
                isCollaborator,
              ),
              _buildTaskSection(
                'En cours',
                inProgressTasks,
                'in_progress',
                project.id,
                isCollaborator,
              ),
              _buildTaskSection(
                'Terminé',
                doneTasks,
                'done',
                project.id,
                isCollaborator,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSection(
    String title,
    List<Map<String, dynamic>> tasks,
    String currentStatus,
    String projectId,
    bool isCollaborator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '$title (${tasks.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Aucune tâche',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...tasks.map(
          (task) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(
                task['title'] ?? 'Sans titre',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: isCollaborator
                  ? PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        if (currentStatus != 'todo')
                          const PopupMenuItem(
                            value: 'todo',
                            child: Text('À faire'),
                          ),
                        if (currentStatus != 'in_progress')
                          const PopupMenuItem(
                            value: 'in_progress',
                            child: Text('En cours'),
                          ),
                        if (currentStatus != 'done')
                          const PopupMenuItem(
                            value: 'done',
                            child: Text('Terminé'),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      onSelected: (action) {
                        if (action == 'delete') {
                          context.read<ProjectProvider>().deleteTask(projectId, task['id']);
                        } else {
                          context.read<ProjectProvider>().updateTaskStatus(
                            projectId,
                            task['id'],
                            action,
                          );
                        }
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
