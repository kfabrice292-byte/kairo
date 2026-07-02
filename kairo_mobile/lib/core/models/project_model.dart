import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String founderId;
  final String founderName;
  final List<String> seekingRoles;
  final List<String> members;
  final bool isOpen;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.founderId,
    required this.founderName,
    required this.seekingRoles,
    this.members = const [],
    this.isOpen = true,
    required this.createdAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      founderId: data['founderId'] ?? '',
      founderName: data['founderName'] ?? 'Anonyme',
      seekingRoles: List<String>.from(data['seekingRoles'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      isOpen: data['isOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'founderId': founderId,
      'founderName': founderName,
      'seekingRoles': seekingRoles,
      'members': members,
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
