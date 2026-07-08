import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'legal_screen.dart';
import 'support_screen.dart';
import 'security_screen.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

import '../../core/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Section Apparence
          _buildSectionHeader('Apparence', theme),
          _buildCardGroup(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.palette(),
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thème',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Clair'),
                            icon: Icon(Icons.light_mode, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Sombre'),
                            icon: Icon(Icons.dark_mode, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Système'),
                            icon: Icon(
                              Icons.settings_system_daydream,
                              size: 18,
                            ),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeProvider.setThemeMode(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Préférences
          _buildSectionHeader('Préférences', theme),
          _buildCardGroup(
            theme,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.translate(),
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Langue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'fr', label: Text('Français')),
                          ButtonSegment(value: 'en', label: Text('English')),
                        ],
                        selected: {settingsProvider.language},
                        onSelectionChanged: (Set<String> newSelection) {
                          settingsProvider.setLanguage(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.lockKey(),
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Confidentialité du profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'public', label: Text('Public')),
                          ButtonSegment(
                            value: 'connections',
                            label: Text('Connexions'),
                          ),
                          ButtonSegment(value: 'private', label: Text('Privé')),
                        ],
                        selected: {settingsProvider.privacy},
                        onSelectionChanged: (Set<String> newSelection) {
                          settingsProvider.setPrivacy(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Notifications
          _buildSectionHeader('Notifications', theme),
          _buildCardGroup(
            theme,
            children: [
              _buildSwitchItem(
                title: 'Notifications Push',
                icon: PhosphorIcons.bell(),
                value: settingsProvider.pushNotifications,
                onChanged: (val) => settingsProvider.setPushNotifications(val),
                theme: theme,
              ),
              _buildSwitchItem(
                title: 'Emails de communauté',
                icon: PhosphorIcons.envelopeSimple(),
                value: settingsProvider.emailNotifications,
                onChanged: (val) => settingsProvider.setEmailNotifications(val),
                theme: theme,
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Informations légales & Support
          _buildSectionHeader('À propos', theme),
          _buildCardGroup(
            theme,
            children: [
              _buildActionItem(
                title: 'Aide & Support',
                icon: PhosphorIcons.question(),
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                },
              ),
              _buildActionItem(
                title: 'Politique de confidentialité',
                icon: PhosphorIcons.shieldCheck(),
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(
                        title: "Politique de confidentialité",
                        content:
                            "Nous accordons une grande importance à la confidentialité de vos données.\n\n"
                            "1. Collecte des données\n"
                            "Nous collectons les informations que vous nous fournissez directement lors de la création de votre compte (nom, email, expériences).\n\n"
                            "2. Utilisation des données\n"
                            "Vos données sont utilisées pour générer votre profil, vos CVs et votre portfolio. Elles ne sont en aucun cas vendues à des tiers.\n\n"
                            "3. Sécurité\n"
                            "Nous mettons en œuvre toutes les mesures techniques pour protéger vos informations contre les accès non autorisés.\n\n"
                            "4. Suppression\n"
                            "Vous pouvez supprimer votre compte à tout moment depuis les paramètres. Toutes vos données seront effacées de nos serveurs.",
                      ),
                    ),
                  );
                },
              ),
              _buildActionItem(
                title: 'Conditions d\'utilisation',
                icon: PhosphorIcons.fileText(),
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalScreen(
                        title: "Conditions d'utilisation",
                        content:
                            "Bienvenue sur Kaïro.\n\n"
                            "1. Acceptation des conditions\n"
                            "En utilisant notre application, vous acceptez de respecter les présentes conditions.\n\n"
                            "2. Utilisation du service\n"
                            "Vous acceptez de n'utiliser Kaïro qu'à des fins professionnelles et légales. Vous êtes responsable du contenu que vous publiez.\n\n"
                            "3. Propriété intellectuelle\n"
                            "Les modèles de CV et la structure de l'application restent la propriété exclusive de Kaïro.\n\n"
                            "4. Modification du service\n"
                            "Kaïro se réserve le droit de modifier ou de suspendre le service à tout moment avec ou sans préavis.",
                      ),
                    ),
                  );
                },
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Compte
          _buildSectionHeader('Compte', theme),
          _buildCardGroup(
            theme,
            children: [
              _buildActionItem(
                title: 'Mot de passe et Sécurité',
                icon: PhosphorIcons.lockKey(),
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  );
                },
              ),
              _buildActionItem(
                title: 'Supprimer mon compte',
                icon: PhosphorIcons.trash(),
                theme: theme,
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _handleDeleteAccount(context),
              ),
              _buildActionItem(
                title: 'Se déconnecter',
                icon: PhosphorIcons.signOut(),
                theme: theme,
                textColor: AppColors.primary,
                iconColor: AppColors.primary,
                onTap: () => _handleLogout(context),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              'Kaïro v1.1.0',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardGroup(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.iconTheme.color, size: 20),
          ),
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.iconTheme.color)?.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? theme.iconTheme.color,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor ?? theme.textTheme.bodyLarge?.color,
            ),
          ),
          trailing: Icon(
            PhosphorIcons.caretRight(),
            size: 16,
            color: theme.dividerColor,
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 60,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront perdues. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        final error = await context.read<AuthProvider>().deleteAccount();
        if (mounted) {
          if (error == null) {
            context.go('/login');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          context.go('/login');
        }
      }
    }
  }
}
