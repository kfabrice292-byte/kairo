import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../core/models/user_model.dart';
import '../core/providers/network_provider.dart';
import '../screens/profile/public_profile_screen.dart';

class ConnectionCard extends StatelessWidget {
  final UserModel user;

  const ConnectionCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null || user.uid == currentUserId)
      return const SizedBox.shrink();

    final connection = networkProvider.getConnectionWith(user.uid);

    Widget actionButton;

    if (connection == null) {
      actionButton = OutlinedButton(
        onPressed: () => networkProvider.sendRequest(user.uid),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text(
          'Se connecter',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    } else if (connection.status == 'accepted') {
      actionButton = TextButton.icon(
        onPressed: () {
          // Open chat or show options
        },
        icon: const Icon(Icons.check, size: 16, color: Colors.green),
        label: const Text(
          'Connecté',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      );
    } else if (connection.senderId == currentUserId) {
      // We sent the request
      actionButton = TextButton.icon(
        onPressed: () => networkProvider.cancelRequest(connection.id),
        icon: const Icon(Icons.access_time, size: 16, color: Colors.grey),
        label: const Text(
          'En attente',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    } else {
      // We received the request
      actionButton = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => networkProvider.rejectRequest(connection.id),
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => networkProvider.acceptRequest(connection.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Accepter',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(userId: user.uid),
              ),
            );
          },
          child: CircleAvatar(
            radius: 28,
            backgroundImage: CachedNetworkImageProvider(
              user.photoURL.isNotEmpty
                  ? user.photoURL
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}',
            ),
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(userId: user.uid),
              ),
            );
          },
          child: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user.fieldOfStudy.isNotEmpty)
              Text(
                user.fieldOfStudy,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (user.university.isNotEmpty || user.country.isNotEmpty)
              Text(
                [
                  user.university,
                  user.country,
                ].where((e) => e.isNotEmpty).join(' • '),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: actionButton,
      ),
    );
  }
}
