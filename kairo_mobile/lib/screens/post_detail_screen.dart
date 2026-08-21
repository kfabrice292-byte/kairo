import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/post_model.dart';
import 'feed_screen.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expérience', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Cette expérience n\'existe plus.'),
            );
          }
          final post = PostModel.fromFirestore(snapshot.data!);
          // The PostCard and Comments logic relies on context providers
          // (FeedProvider, AuthProvider, etc.) which should be available here
          // because they are registered at the root of the app.
          return SingleChildScrollView(
            child: Column(
              children: [
                PostCard(post: post),
                const Divider(),
                // Display the comments for the post by simulating a full height section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: CommentsSheet(postId: postId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
