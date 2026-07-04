import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../profile/public_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (provider.unreadCount > 0)
            IconButton(
              icon: Icon(PhosphorIcons.checks()),
              onPressed: () {
                provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toutes les notifications ont été marquées comme lues.')));
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.bellZ(), size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Aucune notification', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                
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
                    color = const Color(0xFF10B981);
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
                  color: notif.isRead ? Colors.transparent : Colors.orange.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.body, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(notif.createdAt, locale: 'fr'),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        if (notif.type == 'network') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  context.read<AuthProvider>().acceptNetworkRequest(notif.relatedId!);
                                  provider.markAsRead(notif.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation acceptée')));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text('Accepter', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  context.read<AuthProvider>().cancelOrRejectNetworkRequest(notif.relatedId!);
                                  provider.markAsRead(notif.id);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text('Refuser', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    onTap: () {
                      if (!notif.isRead) {
                        provider.markAsRead(notif.id);
                      }
                      if (notif.type == 'network' || notif.type == 'network_accepted') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: notif.relatedId!),
                        ));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
