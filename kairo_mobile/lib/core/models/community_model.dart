import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String iconHex; // Code d'icône Phosphor (optionnel) ou juste un tag
  final String colorHex;
  final int membersCount;
  final List<String> members;
  final String adminId; // Createur/Admin
  final List<String> moderators; // Modérateurs
  final String rules;
  final List<String> tags;
  final String privacy; // 'public' ou 'private'
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconHex = '',
    this.colorHex = 'FF3B82F6',
    this.membersCount = 0,
    this.members = const [],
    required this.adminId,
    this.moderators = const [],
    this.rules = '',
    this.tags = const [],
    this.privacy = 'public',
    required this.createdAt,
  });

  factory CommunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconHex: data['iconHex'] ?? '',
      colorHex: data['colorHex'] ?? 'FF3B82F6',
      membersCount: data['membersCount'] ?? 0,
      members: List<String>.from(data['members'] ?? []),
      adminId: data['adminId'] ?? '',
      moderators: List<String>.from(data['moderators'] ?? []),
      rules: data['rules'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      privacy: data['privacy'] ?? 'public',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconHex': iconHex,
      'colorHex': colorHex,
      'membersCount': membersCount,
      'members': members,
      'adminId': adminId,
      'moderators': moderators,
      'rules': rules,
      'tags': tags,
      'privacy': privacy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
