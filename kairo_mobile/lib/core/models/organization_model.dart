import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String logoUrl;
  final String industry;
  final String website;
  final String description;
  final String location;
  final List<String> members; // UIDs of users who belong to this organization
  final Map<String, dynamic> settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    this.industry = '',
    this.website = '',
    this.description = '',
    this.location = '',
    this.members = const [],
    this.settings = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory OrganizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return OrganizationModel(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      industry: data['industry'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      settings: data['settings'] as Map<String, dynamic>? ?? {},
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'industry': industry,
      'website': website,
      'description': description,
      'location': location,
      'members': members,
      'settings': settings,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
