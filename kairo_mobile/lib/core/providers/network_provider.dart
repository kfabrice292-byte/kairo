import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';

class NetworkProvider extends ChangeNotifier {
  List<ConnectionModel> _connections = [];
  bool _isLoading = false;
  final Map<String, UserModel> usersCache = {};
  
  StreamSubscription? _authSub;
  StreamSubscription? _sentSub;
  StreamSubscription? _receivedSub;

  List<ConnectionModel> get connections => _connections;
  bool get isLoading => _isLoading;

  NetworkProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _cancelSubscriptions();
        _connections.clear();
        _sentConnections.clear();
        _receivedConnections.clear();
        usersCache.clear();
        notifyListeners();
      } else {
        _listenToConnections(user.uid);
      }
    });
  }

  void _cancelSubscriptions() {
    _sentSub?.cancel();
    _sentSub = null;
    _receivedSub?.cancel();
    _receivedSub = null;
  }

  List<ConnectionModel> _sentConnections = [];
  List<ConnectionModel> _receivedConnections = [];

  void _listenToConnections(String currentUserId) {
    _cancelSubscriptions();
    
    _isLoading = true;
    notifyListeners();

    // Listen to connections where current user is sender
    _sentSub = FirebaseFirestore.instance
        .collection('connections')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            _sentConnections = snapshot.docs
                .map((doc) => ConnectionModel.fromFirestore(doc))
                .toList();
            _updateConnections();
          },
          onError: (e) {
            debugPrint('Error fetching sent connections: $e');
            _updateConnections();
          },
        );

    // Listen to connections where current user is receiver
    _receivedSub = FirebaseFirestore.instance
        .collection('connections')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
            _receivedConnections = snapshot.docs
                .map((doc) => ConnectionModel.fromFirestore(doc))
                .toList();
            _updateConnections();
          },
          onError: (e) {
            debugPrint('Error fetching received connections: $e');
            _updateConnections();
          },
        );
  }

  void _updateConnections() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Merge sent and received connections without duplicates
    final all = <ConnectionModel>[..._sentConnections, ..._receivedConnections];
    final map = <String, ConnectionModel>{};
    for (var c in all) {
      map[c.id] = c;
    }
    _connections = map.values.toList();
    _isLoading = false;
    notifyListeners();

    // Fetch missing users for the cache
    final missingUserIds = <String>{};
    for (var conn in _connections) {
      if (conn.senderId != currentUserId) missingUserIds.add(conn.senderId);
      if (conn.receiverId != currentUserId) missingUserIds.add(conn.receiverId);
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

    // Optimistic update
    final newConn = ConnectionModel(
      id: docRef.id,
      senderId: currentUserId,
      receiverId: receiverId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    _connections.add(newConn);
    notifyListeners();

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

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}
