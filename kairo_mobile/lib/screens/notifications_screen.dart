import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../core/providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(PhosphorIcons.checks()),
                tooltip: 'Tout marquer comme lu',
                onPressed: () => provider.markAllAsRead(),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final notifications = provider.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.bellRinging(PhosphorIconsStyle.duotone),
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Vous êtes à jour ! Nous vous préviendrons\ndès qu'il y aura du nouveau.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isApplication = notif.type == 'application_update';
              
              return ListTile(
                onTap: () {
                  if (!notif.isRead) {
                    provider.markAsRead(notif.id);
                  }
                  // Optionally navigate if it's an application update
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
                leading: CircleAvatar(
                  backgroundColor: isApplication ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                  child: Icon(
                    isApplication ? PhosphorIcons.briefcase() : PhosphorIcons.bell(),
                    color: isApplication ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM à HH:mm').format(notif.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                trailing: !notif.isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
