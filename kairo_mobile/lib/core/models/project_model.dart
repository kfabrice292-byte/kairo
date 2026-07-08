import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String title; // "nom"
  final String description;
  final String goals; // "objectifs"
  final String domain; // "domaine" (ex: Tech, Design, Finance)
  final String founderId;
  final String founderName;
  final String founderPhoto;
  final List<String> skillsRequired; // "compétences recherchées"
  final int maxParticipants; // "nombre de participants"
  final String estimatedDuration; // "durée estimée"
  final List<String> members; // IDs des membres actuels
  final List<Map<String, dynamic>> tasks; // Kanban tasks
  final List<String> joinRequests; // IDs de ceux qui veulent rejoindre
  final String status; // 'ideation', 'in_progress', 'completed'
  final List<String> externalLinks;
  final bool isOpen;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    this.goals = '',
    this.domain = 'Général',
    required this.founderId,
    required this.founderName,
    this.founderPhoto = '',
    required this.skillsRequired,
    this.maxParticipants = 5,
    this.estimatedDuration = '',
    this.members = const [],
    this.tasks = const [],
    this.joinRequests = const [],
    this.status = 'ideation',
    this.externalLinks = const [],
    this.isOpen = true,
    required this.createdAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      goals: data['goals'] ?? '',
      domain: data['domain'] ?? 'Général',
      founderId: data['founderId'] ?? '',
      founderName: data['founderName'] ?? 'Anonyme',
      founderPhoto: data['founderPhoto'] ?? '',
      skillsRequired: List<String>.from(data['skillsRequired'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 5,
      estimatedDuration: data['estimatedDuration'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      tasks: List<Map<String, dynamic>>.from(data['tasks'] ?? []),
      joinRequests: List<String>.from(data['joinRequests'] ?? []),
      status: data['status'] ?? 'ideation',
      externalLinks: List<String>.from(data['externalLinks'] ?? []),
      isOpen: data['isOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'goals': goals,
      'domain': domain,
      'founderId': founderId,
      'founderName': founderName,
      'founderPhoto': founderPhoto,
      'skillsRequired': skillsRequired,
      'maxParticipants': maxParticipants,
      'estimatedDuration': estimatedDuration,
      'members': members,
      'tasks': tasks,
      'joinRequests': joinRequests,
      'status': status,
      'externalLinks': externalLinks,
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
