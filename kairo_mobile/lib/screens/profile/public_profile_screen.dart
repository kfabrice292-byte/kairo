import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/push_notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        setState(() {
          _user = UserModel.fromFirestore(doc);
          _isLoading = false;
        });
        
        if (mounted) {
          final currentUser = context.read<AuthProvider>().userModel;
          if (currentUser != null && currentUser.uid != widget.userId) {
            FirebaseFirestore.instance.collection('notifications').add({
              'userId': widget.userId,
              'title': 'Nouvelle visite de profil',
              'body': '${currentUser.name} a visité votre profil',
              'type': 'profile_visit',
              'relatedId': currentUser.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching public profile: $e');
      setState(() => _isLoading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profil')),
        body: const Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider>().userModel?.uid;
    final isMe = currentUserId == _user!.uid;
    
    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _user!.name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: CachedNetworkImageProvider(
                _user!.photoURL.isNotEmpty
                    ? _user!.photoURL
                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user!.name)}',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_user!.fieldOfStudy.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _user!.fieldOfStudy,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            

            if (_user!.bio.isNotEmpty) ...[
              _buildSectionTitle('À propos', theme),
              Text(
                _user!.bio,
                style: TextStyle(
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_user!.skills.isNotEmpty) ...[
              _buildSectionTitle('Compétences', theme),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill.name,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
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
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            if (_user!.experiences.isNotEmpty) ...[
              _buildSectionTitle('Expériences', theme),
              ..._user!.experiences.map((exp) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.briefcase(),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    exp.title,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${exp.organization} • ${exp.period}'),
                );
              }),
            ],

            const SizedBox(height: 32),
            _buildSectionTitle("Partages d'expérience", theme),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}
