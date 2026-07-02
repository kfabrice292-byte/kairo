import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/post_model.dart';

class FeedProvider extends ChangeNotifier {
  List<PostModel> _posts = [];
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;

  FeedProvider() {
    _listenToPosts();
    cleanDummyData();
  }

  Future<void> cleanDummyData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('posts').get();
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
        .listen((snapshot) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      _posts = snapshot.docs.map((doc) {
        final post = PostModel.fromFirestore(doc);
        if (currentUserId != null) {
          post.isLiked = post.likedBy.contains(currentUserId);
        }
        return post;
      }).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching posts: $e');
      _isLoading = false;
      notifyListeners();
    });
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
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'likedBy': isCurrentlyLiked 
              ? FieldValue.arrayRemove([userId]) 
              : FieldValue.arrayUnion([userId]),
        });
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

  Future<void> addComment(String postId, String content) async {
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> addPost(String content, {List<File>? images, bool isStylized = false, int styleIndex = 0}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Fetch actual user data from Firestore to get their real name, fieldOfStudy, and photo
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    
    final authorName = userData['name'] ?? user.displayName ?? 'Étudiant';
    final authorRole = userData['fieldOfStudy']?.toString().isNotEmpty == true 
        ? userData['fieldOfStudy'] 
        : 'Étudiant Kaïro';
    final authorAvatar = userData['photoURL'] ?? user.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(authorName)}&background=F97316&color=fff';

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
