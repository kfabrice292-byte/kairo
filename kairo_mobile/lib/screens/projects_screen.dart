import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/providers/project_provider.dart';
import '../core/models/project_model.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state_widget.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedDomain = 'Tous';
  String _selectedStatus = 'Tous';

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Domaine',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          'Tous',
                          'Tech',
                          'Design',
                          'Finance',
                          'Général',
                          'Marketing',
                        ].map((domain) {
                          final isSelected = _selectedDomain == domain;
                          return ChoiceChip(
                            label: Text(domain),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedDomain = domain);
                                setState(() => _selectedDomain = domain);
                              }
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          {'label': 'Tous', 'value': 'Tous'},
                          {'label': 'Idéation', 'value': 'ideation'},
                          {'label': 'En cours', 'value': 'in_progress'},
                          {'label': 'Terminé', 'value': 'completed'},
                        ].map((statusMap) {
                          final isSelected =
                              _selectedStatus == statusMap['value'];
                          return ChoiceChip(
                            label: Text(statusMap['label']!),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(
                                  () => _selectedStatus = statusMap['value']!,
                                );
                                setState(
                                  () => _selectedStatus = statusMap['value']!,
                                );
                              }
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Appliquer les filtres',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Projets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.faders()),
              onPressed: _showFilterSheet,
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Découvrir'),
              Tab(text: 'Mes projets'),
            ],
          ),
        ),
        body: Consumer<ProjectProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.projects.isEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const ShimmerProjectCard(),
              );
            }

            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            // All projects with filters
            var discoverOps = provider.projects;
            if (_selectedDomain != 'Tous') {
              discoverOps = discoverOps
                  .where((p) => p.domain == _selectedDomain)
                  .toList();
            }
            if (_selectedStatus != 'Tous') {
              discoverOps = discoverOps
                  .where((p) => p.status == _selectedStatus)
                  .toList();
            }

            // My projects (founder or member)
            final myProjects = provider.projects.where((p) {
              return currentUserId != null &&
                  (p.founderId == currentUserId ||
                      p.members.contains(currentUserId));
            }).toList();

            return TabBarView(
              children: [
                _buildList(context, 
                  discoverOps,
                  'Aucun projet trouvé avec ces filtres.',
                ),
                _buildList(context, 
                  myProjects,
                  'Vous ne participez à aucun projet pour le moment.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ProjectModel> projects, String emptyMessage) {
    if (projects.isEmpty && !context.watch<ProjectProvider>().isLoading) {
      return EmptyStateWidget(
        title: 'Aucun projet',
        message: emptyMessage,
        icon: PhosphorIconsLight.rocketLaunch,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ProjectProvider>().loadProjects(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            context.read<ProjectProvider>().loadMoreProjects();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length + (context.watch<ProjectProvider>().hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == projects.length) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 24, top: 16),
                child: ShimmerProjectCard(),
              );
            }
            return _ProjectCard(project: projects[index]);
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isFounder = currentUserId == project.founderId;
    final isMember = project.members.contains(currentUserId);
    final hasRequested = project.joinRequests.contains(currentUserId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(project: project),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        project.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(project.status),
                      style: TextStyle(
                        color: _getStatusColor(project.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Tags
              if (project.skillsRequired.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.skillsRequired
                      .take(3)
                      .map(
                        (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Bottom row: Members & Domain
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          project.domain,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.users(),
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${1 + project.members.length} membres',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isFounder)
                    Icon(Icons.star, color: Colors.orange, size: 20)
                  else if (isMember)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  else if (hasRequested)
                    Icon(
                      Icons.access_time,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'in_progress') return Colors.blue;
    if (status == 'completed') return Colors.green;
    return Colors.purple;
  }

  String _getStatusText(String status) {
    if (status == 'in_progress') return 'En cours';
    if (status == 'completed') return 'Terminé';
    return 'Idéation';
  }
}
