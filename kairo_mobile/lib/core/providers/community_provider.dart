import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_model.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityModel> _communities = [];
  final bool _isLoading = false;

  List<CommunityModel> get communities => _communities;
  bool get isLoading => _isLoading;

  CommunityProvider() {
    _listenToCommunities();
  }

  void _listenToCommunities() {
    FirebaseFirestore.instance
        .collection('communities')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _communities = snapshot.docs.map((doc) => CommunityModel.fromFirestore(doc)).toList();
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error listening to communities: $error');
    });
  }

  Future<void> joinCommunity(String communityId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('communities').doc(communityId).update({
        'members': FieldValue.arrayUnion([userId]),
        'membersCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error joining community: $e');
      rethrow;
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('communities').doc(communityId).update({
        'members': FieldValue.arrayRemove([userId]),
        'membersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error leaving community: $e');
      rethrow;
    }
  }

  // Permet à l'admin de créer une communauté depuis l'app (optionnel)
  Future<void> createCommunity(
    String name, 
    String description, 
    String colorHex, 
    {String privacy = 'public', List<String> tags = const [], String rules = ''}
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('communities').add({
        'name': name,
        'description': description,
        'iconHex': '',
        'colorHex': colorHex,
        'membersCount': 1, 
        'members': [userId],
        'adminId': userId,
        'moderators': <String>[],
        'rules': rules,
        'tags': tags,
        'privacy': privacy,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating community: $e');
      rethrow;
    }
  }
}
