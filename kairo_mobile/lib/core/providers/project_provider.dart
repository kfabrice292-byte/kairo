import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';

class ProjectProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  bool _isLoading = false;

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;

  ProjectProvider() {
    _listenToProjects();
  }

  void _listenToProjects() {
    _isLoading = true;
    notifyListeners();

    FirebaseFirestore.instance
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _projects = snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching projects: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addProject(ProjectModel project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('projects').add(project.toMap());
  }

  Future<void> requestToJoin(String projectId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'joinRequests': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> acceptJoinRequest(String projectId, String userId) async {
    await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'joinRequests': FieldValue.arrayRemove([userId]),
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> refuseJoinRequest(String projectId, String userId) async {
    await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
      'joinRequests': FieldValue.arrayRemove([userId]),
    });
  }
}
