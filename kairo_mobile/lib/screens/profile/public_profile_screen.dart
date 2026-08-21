import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/network_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/push_notification_service.dart';
import '../feed_screen.dart';
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

  void _handleNetworkAction(BuildContext context, String action) async {
    final network = context.read<NetworkProvider>();

    if (action == 'connected') {
      // Pour l'instant, on ne fait rien ou on affiche un message. 
      // La messagerie entre amis est désactivée.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes connectés avec cet utilisateur.')),
      );
      return;
    } else if (action == 'message') {
      try {
        final chatId = await context.read<ChatProvider>().createOrGetChat(
          _user!.uid,
          _user!.name,
          _user!.photoURL,
        );
        if (context.mounted) {
          context.push(
            '/chat_detail',
            extra: {
              'chatId': chatId,
              'otherUserId': _user!.uid,
              'otherUserName': _user!.name,
              'otherUserAvatar': _user!.photoURL,
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du chat.')),
        );
      }
    } else if (action == 'send_request') {
      await network.sendRequest(_user!.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation envoyée à ${_user!.name} !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else if (action == 'accept_request') {
      final conn = network.getConnectionWith(_user!.uid);
      if (conn != null) {
        await network.acceptRequest(conn.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vous êtes maintenant connecté avec ${_user!.name} !',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else if (action == 'cancel_request') {
      final conn = network.getConnectionWith(_user!.uid);
      if (conn != null) {
        await network.cancelRequest(conn.id); // Or reject
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation annulée.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
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
    
    final network = context.watch<NetworkProvider>();
    final connection = network.getConnectionWith(_user!.uid);

    final isConnected = connection?.status == 'accepted';
    final hasSentRequest = connection?.status == 'pending' && connection?.senderId == currentUserId;
    final hasReceivedRequest = connection?.status == 'pending' && connection?.receiverId == currentUserId;

    String action = 'send_request';
    String label = 'Envoyer une invitation';
    IconData icon = PhosphorIcons.userPlus();
    Color bgColor = AppColors.primary;
    Color fgColor = Colors.white;

    if (isConnected) {
      action = 'connected';
      label = 'Connecté(e)';
      icon = PhosphorIcons.checkCircle();
      bgColor = Colors.white;
      fgColor = AppColors.primary;
    } else if (hasSentRequest) {
      action = 'cancel_request';
      label = 'Invitation envoyée (Annuler)';
      icon = PhosphorIcons.clock();
      bgColor = Colors.grey.shade200;
      fgColor = Colors.black87;
    } else if (hasReceivedRequest) {
      action = 'accept_request';
      label = 'Accepter l\'invitation';
      icon = PhosphorIcons.checkCircle();
      bgColor = AppColors.success; // Emerald
      fgColor = Colors.white;
    }

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

            if (!isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleNetworkAction(context, action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    side: isConnected
                        ? BorderSide(color: Theme.of(context).dividerColor)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(icon, size: 20),
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

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
            Consumer<FeedProvider>(
              builder: (context, feedProvider, _) {
                final userPosts = feedProvider.posts
                    .where((p) => p.authorId == _user!.uid)
                    .toList();

                if (userPosts.isEmpty) {
                  return Text(
                    "Aucun partage pour le moment.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                return Column(
                  children: userPosts
                      .map((post) => PostCard(post: post))
                      .toList(),
                );
              },
            ),
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
