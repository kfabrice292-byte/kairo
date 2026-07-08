import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Aide & Support',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            "Foire aux questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            theme,
            "Comment générer mon CV ?",
            "Allez dans l'onglet 'Profil', assurez-vous d'avoir rempli vos expériences et compétences, puis appuyez sur le bouton 'Générer CV'.",
          ),
          _buildFaqItem(
            theme,
            "Comment fonctionne le portfolio ?",
            "Kaïro rassemble automatiquement vos projets et vos expériences pour générer un portfolio en ligne unique, partageable avec les recruteurs.",
          ),
          _buildFaqItem(
            theme,
            "Puis-je modifier mes informations après inscription ?",
            "Oui, vous pouvez à tout moment aller sur votre Profil et cliquer sur l'icône de modification en haut à droite.",
          ),

          const SizedBox(height: 40),
          const Text(
            "Nous contacter",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    "Ouverture du client mail...",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: Colors.blueGrey.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(PhosphorIcons.envelopeSimple(), size: 20),
            label: const Text('Envoyer un e-mail à support@kairo.com'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textTheme.bodyLarge?.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(ThemeData theme, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: theme.iconTheme.color,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
