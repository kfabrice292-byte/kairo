import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/community_model.dart';
import '../../core/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunitySettingsScreen extends StatelessWidget {
  final CommunityModel community;

  const CommunitySettingsScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Paramètres de la communauté',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Icon(PhosphorIcons.pencilSimple(), color: Colors.blue),
              title: const Text('Modifier les informations'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open edit dialog
              },
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Gestion des membres',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Members List
          ...community.members.map(
            (memberId) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(memberId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists)
                  return const SizedBox.shrink();
                final user = UserModel.fromFirestore(snapshot.data!);

                final isAdmin = memberId == community.adminId;
                final isModerator = community.moderators.contains(memberId);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoURL.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL)
                          : null,
                      backgroundColor: Colors.grey.shade300,
                      child: user.photoURL.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isAdmin
                          ? 'Administrateur'
                          : (isModerator ? 'Modérateur' : 'Membre'),
                    ),
                    trailing: isAdmin
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (val) {
                              // TODO: Implement kick, promote, demote logic
                              if (val == 'kick') {
                                // Kick member
                                FirebaseFirestore.instance
                                    .collection('communities')
                                    .doc(community.id)
                                    .update({
                                      'members': FieldValue.arrayRemove([
                                        memberId,
                                      ]),
                                      'membersCount': FieldValue.increment(-1),
                                    });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Membre expulsé.'),
                                  ),
                                );
                              } else if (val == 'promote') {
                                FirebaseFirestore.instance
                                    .collection('communities')
                                    .doc(community.id)
                                    .update({
                                      'moderators': FieldValue.arrayUnion([
                                        memberId,
                                      ]),
                                    });
                              } else if (val == 'demote') {
                                FirebaseFirestore.instance
                                    .collection('communities')
                                    .doc(community.id)
                                    .update({
                                      'moderators': FieldValue.arrayRemove([
                                        memberId,
                                      ]),
                                    });
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isModerator)
                                const PopupMenuItem(
                                  value: 'promote',
                                  child: Text('Promouvoir Modérateur'),
                                ),
                              if (isModerator)
                                const PopupMenuItem(
                                  value: 'demote',
                                  child: Text('Rétrograder Membre'),
                                ),
                              const PopupMenuItem(
                                value: 'kick',
                                child: Text(
                                  'Expulser',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
