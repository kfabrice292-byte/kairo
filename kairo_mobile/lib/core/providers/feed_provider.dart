import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';

class FeedProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;
  final Map<String, UserModel> usersCache = {};

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  FeedProvider() {
    _listenToPosts();
    cleanDummyData();
  }

  Future<void> cleanDummyData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['authorId'] == null || data['authorId'] == '') {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning dummy data: $e');
    }
  }

  void _listenToPosts() {
    _isLoading = true;
    notifyListeners();

    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            _posts = snapshot.docs.map((doc) {
              final post = PostModel.fromFirestore(doc);
              if (currentUserId != null) {
                post.isLiked = post.likedBy.contains(currentUserId);
                post.isSaved = post.savedBy.contains(currentUserId);
              }
              return post;
            }).toList();
            _isLoading = false;
            notifyListeners();

            // Fetch missing users for the cache
            final missingUserIds = _posts
                .map((p) => p.authorId)
                .toSet()
                .difference(usersCache.keys.toSet());

            for (String uid in missingUserIds) {
              if (uid.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get()
                    .then((doc) {
                      if (doc.exists) {
                        usersCache[uid] = UserModel.fromFirestore(doc);
                        notifyListeners();
                      }
                    })
                    .catchError((_) {}); // Ignore errors
              }
            }
          },
          onError: (e) {
            debugPrint('Error fetching posts: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> toggleLike(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final isCurrentlyLiked = post.likedBy.contains(userId);

      // Optimistic update
      post.isLiked = !isCurrentlyLiked;
      if (isCurrentlyLiked) {
        post.likedBy.remove(userId);
      } else {
        post.likedBy.add(userId);
      }
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'likedBy': isCurrentlyLiked
                ? FieldValue.arrayRemove([userId])
                : FieldValue.arrayUnion([userId]),
          },
        );

        // Add Notification
        if (!isCurrentlyLiked && post.authorId != userId) {
          final currentUser = FirebaseAuth.instance.currentUser;
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': post.authorId,
            'title': 'Nouveau j\'aime',
            'body':
                '${currentUser?.displayName ?? "Quelqu'un"} a aimé votre publication.',
            'type': 'post',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'relatedId': postId,
          });
        }
      } catch (e) {
        debugPrint('Error toggling like: $e');
        // Revert optimistic update
        post.isLiked = isCurrentlyLiked;
        if (isCurrentlyLiked) {
          post.likedBy.add(userId);
        } else {
          post.likedBy.remove(userId);
        }
        notifyListeners();
      }
    }
  }

  Future<void> toggleSave(String postId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final isCurrentlySaved = post.savedBy.contains(userId);

      // Optimistic update
      post.isSaved = !isCurrentlySaved;
      if (isCurrentlySaved) {
        post.savedBy.remove(userId);
      } else {
        post.savedBy.add(userId);
      }
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'savedBy': isCurrentlySaved
                ? FieldValue.arrayRemove([userId])
                : FieldValue.arrayUnion([userId]),
          },
        );
      } catch (e) {
        debugPrint('Error toggling save: $e');
        // Revert optimistic update
        post.isSaved = isCurrentlySaved;
        if (isCurrentlySaved) {
          post.savedBy.add(userId);
        } else {
          post.savedBy.remove(userId);
        }
        notifyListeners();
      }
    }
  }

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || content.isEmpty) return;

    try {
      final commentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Utilisateur',
        'authorAvatar': user.photoURL,
        'content': content,
        'parentId': parentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      // Add Notification
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      final postAuthorId = postDoc.data()?['authorId'] as String?;
      if (postAuthorId != null && postAuthorId != user.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': postAuthorId,
          'title': 'Nouveau commentaire',
          'body':
              '${user.displayName ?? "Quelqu'un"} a commenté votre publication.',
          'type': 'post',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': postId,
        });
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addPost(
    String content, {
    List<File>? images,
    bool isStylized = false,
    int styleIndex = 0,
    String? category,
    Map<String, dynamic> customFields = const {},
    List<String> tags = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch actual user data from Firestore to get their real name, fieldOfStudy, and photo
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    final authorName = userData['name'] ?? user.displayName ?? 'Étudiant';
    final authorRole =
        userData['professionalTitle']?.toString().isNotEmpty == true
        ? userData['professionalTitle']
        : (userData['fieldOfStudy']?.toString().isNotEmpty == true
              ? userData['fieldOfStudy']
              : 'Ajouter un titre professionnel');
    final authorAvatar =
        userData['photoURL'] ??
        user.photoURL ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(authorName)}&background=F97316&color=fff';

    List<String> uploadedImageUrls = [];

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        try {
          final bytes = await image.readAsBytes();
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
            uploadedImageUrls.add(jsonResponse['data']['display_url']);
          } else {
            debugPrint('ImgBB API Error: ${response.body}');
          }
        } catch (e) {
          debugPrint('ImgBB Upload Exception: $e');
        }
      }
    }

    final newPost = PostModel(
      id: '', // Generated by Firestore
      authorId: user.uid,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorAvatar,
      content: content,
      category: category,
      customFields: customFields,
      tags: tags,
      imageUrls: uploadedImageUrls,
      isStylized: isStylized,
      styleIndex: styleIndex,
      likedBy: [],
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.collection('posts').add(newPost.toMap());
  }

  Future<void> deletePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }
}
