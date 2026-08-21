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
import 'profile/add_language_sheet.dart';
import 'profile/add_education_sheet.dart';
import 'package:kairo_mobile/screens/profile/cover_letter_screen.dart';
import 'profile/add_tags_sheet.dart';

import 'profile/add_tags_sheet.dart';
import 'premium/premium_subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gear()),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
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
                                  _EditProfileDialog(user: user),
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CVEditScreen(user: user),
                                    ),
                                  );
                                },
                                icon: Icon(PhosphorIcons.fileText(), size: 18),
                                label: const Text('Générer CV'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      theme.textTheme.bodyLarge?.color,
                                  side: BorderSide(color: theme.dividerColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PortfolioEditScreen(user: user),
                                    ),
                                  );
                                },
                                icon: Icon(PhosphorIcons.briefcase(), size: 18),
                                label: const Text('Portfolio'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      theme.textTheme.bodyLarge?.color,
                                  side: BorderSide(color: theme.dividerColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CoverLetterScreen(),
                                ),
                              );
                            },
                            icon: Icon(PhosphorIcons.robot(), size: 18),
                            label: const Text('Générer Lettre'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textTheme.bodyLarge?.color,
                              side: BorderSide(color: theme.dividerColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (!user.isPremium) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumSubscriptionScreen()));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.briefcase(PhosphorIconsStyle.fill), color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Découvrir Kaïro Pro',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (user.bio.isNotEmpty)
                          _buildSection('À propos', [
                            Text(
                              user.bio,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.8),
                                height: 1.5,
                                fontSize: 15,
                              ),
                            ),
                          ], theme),
                        const SizedBox(height: 24),
                        _buildTagsSection(context, user, theme),
                        const SizedBox(height: 24),

                        _buildSection(
                          'Compétences',
                          [
                            if (user.skills.isEmpty)
                              const Text(
                                "Aucune compétence ajoutée.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.skills
                                    .map(
                                      (skill) => InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            builder: (context) => AddSkillSheet(user: user, initialSkill: skill),
                                          );
                                        },
                                        child: Container(
                                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppColors.primary.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  skill.name,
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  skill.level,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  _showDeleteConfirmation(context, 'cette compétence', () {
                                                    context.read<AuthProvider>().deleteSkill(skill.name);
                                                  });
                                                },
                                                child: Icon(Icons.close, size: 14, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                          theme,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => AddSkillSheet(user: user),
                              );
                            },
                          ),
                        ),
                        
                        _buildSection(
                          'Langues',
                          [
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
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(lang.name, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('${lang.level}/5', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          _showDeleteConfirmation(context, 'cette langue', () {
                                            context.read<AuthProvider>().deleteLanguage(lang.name);
                                          });
                                        },
                                        child: Icon(Icons.close, size: 14, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ),
                          ],
                          theme,
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => const AddLanguageSheet(),
                              );
                            },
                          ),
                        ),

                        _buildSection(
                          'Formation',
                          [
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
                                              Text(edu.period, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                    Text(edu.institution, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), fontSize: 14)),
                                    if (edu.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(edu.description, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                                    ],
                                  ],
                                ),
                              )),
                          ],
                          theme,
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => const AddEducationSheet(),
                              );
                            },
                          ),
                        ),

                        _buildSection(
                          'Expériences',
                          [
                            if (user.experiences.isEmpty)
                              const Text(
                                "Aucune expérience ajoutée.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ...user.experiences.map(
                                (exp) =>
                                    _buildExperienceCard(exp, theme, context),
                              ),
                          ],
                          theme,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) =>
                                    const AddExperienceSheet(),
                              );
                            },
                          ),
                        ),



                        if (user.portfolioProjects.isNotEmpty || true)
                          _buildSection(
                            'Mes Projets Portfolio',
                            [
                              if (user.portfolioProjects.isEmpty)
                                Text(
                                  'Aucun projet ajouté pour le moment.',
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.work, color: AppColors.primary),
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
                                            Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              if (true) ...[
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
                            ],
                            theme,
                          ),

                        if (user.github.isNotEmpty ||
                            user.linkedin.isNotEmpty ||
                            user.website.isNotEmpty ||
                            user.behance.isNotEmpty)
                          _buildSection('Liens & Portfolio', [
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
                          ], theme),
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

  Widget _buildSection(
    String title,
    List<Widget> children,
    ThemeData theme, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: -0.3,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExperienceCard(
    Experience exp,
    ThemeData theme,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exp.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exp.period,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (val) async {
                      if (val == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) =>
                              AddExperienceSheet(experience: exp),
                        );
                      } else if (val == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Supprimer'),
                            content: const Text(
                              'Voulez-vous vraiment supprimer cette expérience ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await context.read<AuthProvider>().deleteExperience(
                              exp.id,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exp.organization,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
                height: 1.4,
                fontSize: 13,
              ),
              softWrap: true,
            ),
          ],
        ],
      ),
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

class _EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _fieldController = TextEditingController();
  final _levelController = TextEditingController();
  final _universityController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  File? _newImage;
  File? _newCoverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(widget.user);
  }

  void _loadUserData(UserModel user) {
    _nameController.text = user.name;
    _titleController.text = user.professionalTitle;
    _bioController.text = user.bio;
    _fieldController.text = user.fieldOfStudy;
    _levelController.text = user.studyLevel;
    _universityController.text = user.university;
    _countryController.text = user.country;
    _cityController.text = user.city;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _fieldController.dispose();
    _levelController.dispose();
    _universityController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isCover = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isCover
                ? CropAspectRatioPreset.ratio16x9
                : CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Recadrer', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          if (isCover) {
            _newCoverImage = File(croppedFile.path);
          } else {
            _newImage = File(croppedFile.path);
          }
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    String? photoUrl;
    String? coverUrl;

    Future<String?> uploadToImgBB(File imageFile) async {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': '42583eab8962481f83526a0882f3d384',
            'image': base64Image,
          },
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return jsonResponse['data']['display_url'];
        }
      } catch (e) {
        debugPrint('Error uploading image to ImgBB: $e');
      }
      return null;
    }

    if (_newImage != null) {
      photoUrl = await uploadToImgBB(_newImage!);
    }
    if (_newCoverImage != null) {
      coverUrl = await uploadToImgBB(_newCoverImage!);
    }

    final updateData = {
      'name': _nameController.text.trim(),
      'professionalTitle': _titleController.text.trim(),
      'bio': _bioController.text.trim(),
      'fieldOfStudy': _fieldController.text.trim(),
      'studyLevel': _levelController.text.trim(),
      'university': _universityController.text.trim(),
      'country': _countryController.text.trim(),
      'city': _cityController.text.trim(),
    };

    if (photoUrl != null) {
      updateData['photoURL'] = photoUrl;
    }
    if (coverUrl != null) {
      updateData['coverPhoto'] = coverUrl;
    }

    try {
      await context.read<AuthProvider>().updateProfile(updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Éditer mon profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    // Cover photo preview
                    GestureDetector(
                      onTap: () => _pickImage(isCover: true),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _newCoverImage != null
                              ? DecorationImage(
                                  image: FileImage(_newCoverImage!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.user.coverPhoto.isNotEmpty
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          widget.user.coverPhoto,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            _newCoverImage == null &&
                                widget.user.coverPhoto.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                ),
                              )
                            : Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).cardColor,
                                    shadows: [
                                      Shadow(
                                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _pickImage(isCover: false),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _newImage != null
                                ? FileImage(_newImage!) as ImageProvider
                                : (widget.user.photoURL.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          widget.user.photoURL,
                                        )
                                      : null),
                            child:
                                _newImage == null &&
                                    widget.user.photoURL.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Informations de base",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              KairoTextField(
                controller: _nameController,
                hintText: 'Nom Complet',
                prefixIcon: PhosphorIcons.user(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _titleController,
                hintText: 'Titre professionnel (ex: Développeur Flutter)',
                prefixIcon: PhosphorIcons.briefcase(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _bioController,
                hintText: 'Bio rapide...',
                prefixIcon: PhosphorIcons.textAa(),
                maxLength: 160,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              const Text(
                "Études & Localisation",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              KairoTextField(
                controller: _fieldController,
                hintText: 'Filière d\'études',
                prefixIcon: PhosphorIcons.student(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _levelController,
                hintText: 'Niveau (ex: Bac+3, Master)',
                prefixIcon: PhosphorIcons.certificate(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _universityController,
                hintText: 'Université / École',
                prefixIcon: PhosphorIcons.bank(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KairoTextField(
                      controller: _cityController,
                      hintText: 'Ville',
                      prefixIcon: PhosphorIcons.buildings(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KairoTextField(
                      controller: _countryController,
                      hintText: 'Pays (ex: 🇫🇷 France)',
                      prefixIcon: PhosphorIcons.mapPin(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).cardColor,
                        ),
                      )
                    : Text(
                        'Sauvegarder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
