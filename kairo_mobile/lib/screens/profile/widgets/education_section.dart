import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../add_education_sheet.dart';
import 'profile_section.dart';

class EducationSection extends StatelessWidget {
  final UserModel user;

  const EducationSection({super.key, required this.user});

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
      title: 'Formation',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => const AddEducationSheet(),
          );
        },
      ),
      children: [
        if (user.educations.isEmpty)
          const Text(
            "Aucune formation ajoutée.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          ...user.educations.map((edu) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(edu.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(edu.period, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => AddEducationSheet(education: edu),
                              );
                            },
                            child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _showDeleteConfirmation(context, 'cette formation', () {
                                context.read<AuthProvider>().deleteEducation(edu.id);
                              });
                            },
                            child: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(edu.institution, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 14)),
                if (edu.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(edu.description, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13, height: 1.4)),
                ],
              ],
            ),
          )),
      ],
    );
  }
}
