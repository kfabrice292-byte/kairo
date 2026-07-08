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
        .listen(
          (snapshot) {
            _projects = snapshot.docs
                .map((doc) => ProjectModel.fromFirestore(doc))
                .toList();
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error fetching projects: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> addProject(ProjectModel project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('projects')
        .add(project.toMap());
  }

  Future<void> requestToJoin(String projectId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'joinRequests': FieldValue.arrayUnion([userId]),
        });
  }

  Future<void> acceptJoinRequest(String projectId, String userId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'joinRequests': FieldValue.arrayRemove([userId]),
          'members': FieldValue.arrayUnion([userId]),
        });
  }

  Future<void> refuseJoinRequest(String projectId, String userId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'joinRequests': FieldValue.arrayRemove([userId]),
        });
  }

  Future<void> removeMember(String projectId, String userId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'members': FieldValue.arrayRemove([userId]),
        });
  }

  Future<void> addTask(String projectId, Map<String, dynamic> task) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
          'tasks': FieldValue.arrayUnion([task]),
        });
  }

  Future<void> updateTaskStatus(
    String projectId,
    String taskId,
    String newStatus,
  ) async {
    // We need to fetch the document first, find the task, modify it and save back.
    // In a real app we'd use a transaction or a subcollection for concurrent writes,
    // but for this MVP, fetching and updating is fine.
    final docRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> tasksData = data['tasks'] ?? [];

    final updatedTasks = tasksData.map((t) {
      if (t['id'] == taskId) {
        return {...t as Map<String, dynamic>, 'status': newStatus};
      }
      return t;
    }).toList();

    await docRef.update({'tasks': updatedTasks});
  }
}
