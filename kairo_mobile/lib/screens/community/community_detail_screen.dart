import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/community_provider.dart';
import '../../core/models/community_model.dart';
import '../../core/providers/feed_provider.dart';
import '../feed_screen.dart'; // Pour PostCard
import 'community_settings_screen.dart';

class CommunityDetailScreen extends StatelessWidget {
  final CommunityModel community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMember = community.members.contains(userId);
    final color = Color(int.tryParse(community.colorHex, radix: 16) ?? 0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (userId == community.adminId || community.moderators.contains(userId))
            IconButton(
              icon: Icon(PhosphorIcons.gear()),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CommunitySettingsScreen(community: community)));
              },
            ),
          IconButton(
            icon: Icon(PhosphorIcons.info()),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête de la communauté
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    community.name.substring(0, 2).toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  community.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIcons.users(), size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text('${community.members.length} membres', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isMember) {
                        context.read<CommunityProvider>().leaveCommunity(community.id);
                      } else {
                        context.read<CommunityProvider>().joinCommunity(community.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember ? Colors.grey.shade200 : color,
                      foregroundColor: isMember ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(isMember ? 'Quitter la communauté' : 'Rejoindre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          
          // Fil d'actualité exclusif
          Expanded(
            child: isMember 
              ? Consumer<FeedProvider>(
                  builder: (context, provider, child) {
                    // Pour l'instant on filtre le feed global en simulant un feed de commuanuté
                    // Idéalement, les posts auraient un champ 'communityId'
                    final posts = provider.posts.where((p) => p.content.toLowerCase().contains(community.name.toLowerCase()) || provider.posts.indexOf(p) % 3 == 0).toList();
                    
                    if (posts.isEmpty) {
                      return Center(
                        child: Text("Aucune publication dans cette communauté.", style: TextStyle(color: Colors.grey.shade500)),
                      );
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: posts[index]);
                      },
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.lockKey(), size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("Rejoignez la communauté\npour voir les publications.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: isMember ? FloatingActionButton(
        onPressed: () {
          // TODO: Open CreatePostModal with community context
        },
        backgroundColor: color,
        child: const Icon(Icons.edit, color: Colors.white),
      ) : null,
    );
  }
}
