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

  Future<String> addProject(ProjectModel project) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté.");

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('projects')
          .add(project.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding project: $e');
      throw Exception('Erreur lors de la création du projet : $e');
    }
  }

  Future<void> requestToJoin(String projectId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception("Utilisateur non connecté.");

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'joinRequests': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error requesting to join: $e');
      throw Exception('Erreur lors de la demande de participation : $e');
    }
  }

  Future<void> acceptJoinRequest(String projectId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'joinRequests': FieldValue.arrayRemove([userId]),
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error accepting request: $e');
      throw Exception('Erreur lors de l\'acceptation : $e');
    }
  }

  Future<void> refuseJoinRequest(String projectId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'joinRequests': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error refusing request: $e');
      throw Exception('Erreur lors du refus : $e');
    }
  }

  Future<void> removeMember(String projectId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error removing member: $e');
      throw Exception('Erreur lors du retrait du membre : $e');
    }
  }

  Future<void> addTask(String projectId, Map<String, dynamic> task) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'tasks': FieldValue.arrayUnion([task]),
      });
    } catch (e) {
      debugPrint('Error adding task: $e');
      throw Exception('Erreur lors de l\'ajout de la tâche : $e');
    }
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

  Future<void> deleteTask(String projectId, String taskId) async {
    final docRef = FirebaseFirestore.instance.collection('projects').doc(projectId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final List<dynamic> tasksData = data['tasks'] ?? [];

    final updatedTasks = tasksData.where((t) => t['id'] != taskId).toList();

    await docRef.update({'tasks': updatedTasks});
  }
}
