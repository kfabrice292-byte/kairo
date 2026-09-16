import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../add_language_sheet.dart';
import 'profile_section.dart';

class LanguagesSection extends StatelessWidget {
  final UserModel user;

  const LanguagesSection({super.key, required this.user});

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
    return ProfileSection(
      title: 'Langues',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => const AddLanguageSheet(),
          );
        },
      ),
      children: [
        if (user.languages.isEmpty)
          const Text(
            "Aucune langue ajoutée.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lang.name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${lang.level}/5', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      _showDeleteConfirmation(context, 'cette langue', () {
                        context.read<AuthProvider>().deleteLanguage(lang.name);
                      });
                    },
                    child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }
}
