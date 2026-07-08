import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';

class NetworkProvider extends ChangeNotifier {
  List<ConnectionModel> _connections = [];
  bool _isLoading = false;
  final Map<String, UserModel> usersCache = {};

  List<ConnectionModel> get connections => _connections;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    _listenToConnections();
  }

  void _listenToConnections() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    // Listen to connections where current user is either sender or receiver
    FirebaseFirestore.instance
        .collection('connections')
        .where(
          Filter.or(
            Filter('senderId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId),
          ),
        )
        .snapshots()
        .listen(
          (snapshot) {
            _connections = snapshot.docs
                .map((doc) => ConnectionModel.fromFirestore(doc))
                .toList();
            _isLoading = false;
            notifyListeners();

            // Fetch missing users for the cache
            final missingUserIds = <String>{};
            for (var conn in _connections) {
              if (conn.senderId != currentUserId)
                missingUserIds.add(conn.senderId);
              if (conn.receiverId != currentUserId)
                missingUserIds.add(conn.receiverId);
            }

            final toFetch = missingUserIds.difference(usersCache.keys.toSet());
            for (String uid in toFetch) {
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
                    .catchError((_) {});
              }
            }
          },
          onError: (e) {
            debugPrint('Error fetching connections: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  ConnectionModel? getConnectionWith(String targetUserId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      return _connections.firstWhere(
        (c) =>
            (c.senderId == currentUserId && c.receiverId == targetUserId) ||
            (c.receiverId == currentUserId && c.senderId == targetUserId),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> sendRequest(String receiverId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == receiverId) return;

    final existing = getConnectionWith(receiverId);
    if (existing != null) return;

    final docRef = FirebaseFirestore.instance.collection('connections').doc();
    await docRef.set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send Notification
    await _sendNotification(
      receiverId,
      'Nouvelle demande',
      'Vous avez reçu une demande de connexion.',
    );
  }

  Future<void> acceptRequest(String connectionId) async {
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(connectionId)
        .update({'status': 'accepted'});

    final conn = _connections.firstWhere((c) => c.id == connectionId);
    await _sendNotification(
      conn.senderId,
      'Demande acceptée',
      'Votre demande de connexion a été acceptée.',
    );
  }

  Future<void> rejectRequest(String connectionId) async {
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(connectionId)
        .delete();
  }

  Future<void> cancelRequest(String connectionId) async {
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(connectionId)
        .delete();
  }

  Future<void> removeConnection(String connectionId) async {
    await FirebaseFirestore.instance
        .collection('connections')
        .doc(connectionId)
        .delete();
  }

  Future<void> _sendNotification(
    String targetUserId,
    String title,
    String body,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': targetUserId,
        'title': title,
        'body': body,
        'type': 'network',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending network notification: $e');
    }
  }
}
