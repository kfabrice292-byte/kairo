import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../add_portfolio_project_sheet.dart';
import 'profile_section.dart';

class ProjectsSection extends StatelessWidget {
  final UserModel user;

  const ProjectsSection({super.key, required this.user});

  void _showDeleteConfirmation(BuildContext context, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer $itemName ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Supprimé avec succès')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfileSection(
      title: 'Mes Projets Portfolio',
      children: [
        if (user.portfolioProjects.isEmpty)
          Text(
            'Aucun projet ajouté pour le moment.',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          )
        else
          ...user.portfolioProjects.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: p.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        width: 60, height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.work, color: AppColors.primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (context) => AddPortfolioProjectSheet(projectToEdit: p),
                                  );
                                },
                                child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  _showDeleteConfirmation(context, 'ce projet', () {
                                    context.read<AuthProvider>().deletePortfolioProject(p.id);
                                  });
                                },
                                child: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8))),
                    ],
                  ),
                ),
              ],
            ),
          )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => const AddPortfolioProjectSheet(),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Ajouter un projet'),
          ),
        ),
      ],
    );
  }
}
