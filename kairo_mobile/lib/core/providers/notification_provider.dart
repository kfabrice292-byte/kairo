import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  StreamSubscription? _sub;

  NotificationProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToNotifications(user.uid);
      } else {
        _sub?.cancel();
        _notifications = [];
        notifyListeners();
      }
    });
  }

  void _subscribeToNotifications(String userId) {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
            // Sort locally to avoid Firebase index error
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _notifications = list;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error fetching notifications: $error');
          },
        );
  }

  Future<void> markAsRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead);
    final batch = FirebaseFirestore.instance.batch();
    for (var n in unread) {
      batch.update(
        FirebaseFirestore.instance.collection('notifications').doc(n.id),
        {'isRead': true},
      );
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
