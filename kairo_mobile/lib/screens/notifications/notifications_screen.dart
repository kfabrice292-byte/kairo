import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../profile/public_profile_screen.dart';
import '../post_detail_screen.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (provider.unreadCount > 0)
            IconButton(
              icon: Icon(PhosphorIcons.checks()),
              onPressed: () {
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Toutes les notifications ont été marquées comme lues.',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                title: 'Aucune notification',
                message: 'Vous n\'avez pas encore de nouvelles notifications.',
                icon: PhosphorIconsLight.bellZ,
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
                bool hasPendingRequest = false;
                if (notif.relatedId != null) {
                  final conn = networkProvider.getConnectionWith(notif.relatedId!);
                  final currentUserId = context.read<AuthProvider>().userModel?.uid;
                  hasPendingRequest = conn != null && 
                                      conn.status == 'pending' && 
                                      conn.receiverId == currentUserId;
                }
                
                IconData icon;
                Color color;
                switch (notif.type) {
                  case 'community':
                    icon = PhosphorIcons.users();
                    color = Colors.blue;
                    break;
                  case 'project':
                    icon = PhosphorIcons.rocketLaunch();
                    color = Colors.purple;
                    break;
                  case 'post':
                    icon = PhosphorIcons.chatTeardrop();
                    color = Colors.orange;
                    break;
                  case 'network':
                    icon = PhosphorIcons.userPlus();
                    color = AppColors.success;
                    break;
                  case 'network_accepted':
                    icon = PhosphorIcons.checkCircle();
                    color = Colors.green;
                    break;
                  default:
                    icon = PhosphorIcons.info();
                    color = Colors.grey;
                }

                return Container(
                  color: notif.isRead
                      ? Colors.transparent
                      : Colors.orange.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif.body,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(notif.createdAt, locale: 'fr'),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        if (notif.type == 'network' && hasPendingRequest) ...[
                          const SizedBox(height: 8),
                          _NetworkActionButtons(
                            notif: notif,
                            provider: provider,
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      if (!notif.isRead) {
                        provider.markAsRead(notif.id);
                      }
                      if (notif.relatedId == null) return;
                      if (notif.type == 'network' ||
                          notif.type == 'network_accepted') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfileScreen(userId: notif.relatedId!),
                          ),
                        );
                      } else if (notif.type == 'post' ||
                          notif.type == 'comment') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PostDetailScreen(postId: notif.relatedId!),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _NetworkActionButtons extends StatefulWidget {
  final dynamic notif;
  final NotificationProvider provider;

  const _NetworkActionButtons({required this.notif, required this.provider});

  @override
  State<_NetworkActionButtons> createState() => _NetworkActionButtonsState();
}

class _NetworkActionButtonsState extends State<_NetworkActionButtons> {
  bool _isLoading = false;

  Future<void> _handleAction(bool accept) async {
    setState(() => _isLoading = true);
    try {
      final conn = network.getConnectionWith(widget.notif.relatedId!);
      
      if (conn != null) {
        if (accept) {
          await network.acceptRequest(conn.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation acceptée'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          await network.cancelRequest(conn.id);
        }
      }
      widget.provider.markAsRead(widget.notif.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 32,
        width: 32,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Row(
      children: [
        ElevatedButton(
          onPressed: () => _handleAction(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Theme.of(context).iconTheme.color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            minimumSize: const Size(0, 32),
          ),
          child: Text('Accepter', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _handleAction(false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            minimumSize: const Size(0, 32),
          ),
          child: Text('Refuser', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
