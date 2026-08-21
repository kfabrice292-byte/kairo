import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';

class LearningProvider extends ChangeNotifier {
  List<CourseModel> _courses = [];
  bool _isLoading = false;
  
  // Keep track of subscriptions
  StreamSubscription? _authSub;
  StreamSubscription? _coursesSub;

  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;

  LearningProvider() {
    // Listen to auth state changes to start/stop Firestore streams
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _cancelSubscriptions();
        _courses.clear();
        notifyListeners();
      } else {
        _listenToCourses();
      }
    });
  }

  void _cancelSubscriptions() {
    _coursesSub?.cancel();
    _coursesSub = null;
  }

  void _listenToCourses() {
    _cancelSubscriptions();
    _isLoading = true;
    notifyListeners();

    _coursesSub = FirebaseFirestore.instance
        .collection('courses')
        .snapshots()
        .listen(
      (snapshot) {
        _courses = snapshot.docs.map((doc) {
          final data = doc.data();
          return CourseModel(
            id: doc.id,
            title: data['title'] ?? 'Sans titre',
            instructor: data['instructor'] ?? 'Instructeur inconnu',
            category: data['category'] ?? 'Général',
          );
        }).toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error fetching courses: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}
