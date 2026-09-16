import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../core/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/utils/portfolio_generator.dart';
import '../core/utils/payment_utils.dart';
import '../core/services/activity_logger_service.dart';
import 'profile/cv_edit_screen.dart';
import 'settings/settings_screen.dart';
import 'profile/cover_letter_screen.dart';
import 'profile/portfolio_edit_screen.dart';
import '../widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'profile/add_skill_sheet.dart';
import 'profile/add_experience_sheet.dart';
import 'profile/add_portfolio_project_sheet.dart';
import 'profile/add_tags_sheet.dart';
import 'profile/widgets/edit_profile_dialog.dart';
import 'profile/widgets/experiences_section.dart';
import 'profile/widgets/education_section.dart';
import 'profile/widgets/skills_section.dart';
import 'profile/widgets/languages_section.dart';
import 'profile/widgets/projects_section.dart';
import 'premium/premium_subscription_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  double _calculateCompletion(UserModel user) {
    int total = 7;
    int current = 0;
    if (user.name.isNotEmpty) current++;
    if (user.photoURL.isNotEmpty) current++;
    if (user.professionalTitle.isNotEmpty) current++;
    if (user.bio.isNotEmpty) current++;
    if (user.fieldOfStudy.isNotEmpty) current++;
    if (user.skills.isNotEmpty) current++;
    if (user.experiences.isNotEmpty) current++;
    return current / total;
  }

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
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final name = user.name.isNotEmpty ? user.name : 'Utilisateur';
    final photoURL = user.photoURL.isNotEmpty
        ? user.photoURL
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=F97316&color=fff';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mon Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Banner (Couverture)
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: user.coverPhoto.isEmpty
                          ? const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFB923C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: user.coverPhoto.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                user.coverPhoto,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  // Contenu principal (Avatar + Infos)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  EditProfileDialog(user: user),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardColor,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundImage: CachedNetworkImageProvider(
                                    photoURL,
                                  ),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).cardColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Theme.of(context).cardColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (user.isPremium)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Tooltip(
                                  message: user.premiumUntil != null 
                                      ? 'Premium jusqu\'au ${user.premiumUntil!.day.toString().padLeft(2, '0')}/${user.premiumUntil!.month.toString().padLeft(2, '0')}/${user.premiumUntil!.year}'
                                      : 'Premium à vie',
                                  child: const Icon(Icons.verified, color: Colors.blue, size: 20),
                                ),
                              ),
                          ],
                        ),
                        if (user.isPremium && user.premiumUntil != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Valide jusqu\'au ${user.premiumUntil!.day.toString().padLeft(2, '0')}/${user.premiumUntil!.month.toString().padLeft(2, '0')}/${user.premiumUntil!.year}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (user.professionalTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user.professionalTitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          user.fieldOfStudy.isEmpty
                              ? 'Complétez votre profil'
                              : '${user.fieldOfStudy}${user.studyLevel.isNotEmpty ? ' • ${user.studyLevel}' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final completion = _calculateCompletion(user);
                            if (completion >= 1.0)
                              return const SizedBox.shrink();
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Complétion du profil',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '${(completion * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: completion,
                                    backgroundColor: Colors.grey.shade200,
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.city.isEmpty && user.country.isEmpty
                              ? 'Localisation non renseignée'
                              : '${user.city}, ${user.country}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 24),

                        const SizedBox(height: 24),

                        if (user.bio.isNotEmpty)
                          ProfileSection(
                            title: 'À propos',
                            children: [
                              Text(
                                user.bio,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.8),
                                  height: 1.5,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        _buildTagsSection(context, user, theme),
                        const SizedBox(height: 24),

                        SkillsSection(user: user),
                        
                        LanguagesSection(user: user),

                        EducationSection(user: user),

                        ExperiencesSection(user: user),



                        if (user.portfolioProjects.isNotEmpty || true)
                          ProjectsSection(user: user),

                        if (user.github.isNotEmpty ||
                            user.linkedin.isNotEmpty ||
                            user.website.isNotEmpty ||
                            user.behance.isNotEmpty)
                          ProfileSection(
                            title: 'Liens & Portfolio',
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (user.github.isNotEmpty)
                                    _buildSocialLink(
                                      PhosphorIcons.githubLogo(),
                                      'GitHub',
                                      user.github,
                                    ),
                                  if (user.linkedin.isNotEmpty)
                                    _buildSocialLink(
                                      PhosphorIcons.linkedinLogo(),
                                      'LinkedIn',
                                      user.linkedin,
                                    ),
                                  if (user.behance.isNotEmpty)
                                    _buildSocialLink(
                                      PhosphorIcons.behanceLogo(),
                                      'Behance',
                                      user.behance,
                                    ),
                                  if (user.website.isNotEmpty)
                                    _buildSocialLink(
                                      PhosphorIcons.globe(),
                                      'Website',
                                      user.website,
                                    ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTagsSection(BuildContext context, UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Centres d\'intérêt (Tags)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddTagsSheet(user: user),
                );
              },
            ),
          ],
        ),
        if (user.tags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Ajoutez des mots-clés pour recevoir des offres ciblées.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                side: BorderSide.none,
                deleteIcon: Icon(Icons.close, size: 14, color: AppColors.primary),
                onDeleted: () {
                  _showDeleteConfirmation(context, 'ce tag', () async {
                     final updatedTags = List<String>.from(user.tags)..remove(tag);
                     await context.read<AuthProvider>().updateProfile({'tags': updatedTags});
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }




  Widget _buildSocialLink(IconData icon, String label, String url) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade800),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}


