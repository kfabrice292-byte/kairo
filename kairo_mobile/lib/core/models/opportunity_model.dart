import 'package:cloud_firestore/cloud_firestore.dart';

class OpportunityModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type; // Stage, Emploi, Bourse, Concours
  final String description;
  final String postedBy; // User ID of the student who posted
  final List<String> applicants; // IDs of users who applied
  final DateTime createdAt;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.description,
    required this.postedBy,
    this.applicants = const [],
    required this.createdAt,
  });

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OpportunityModel(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      type: data['type'] ?? 'Stage',
      description: data['description'] ?? '',
      postedBy: data['postedBy'] ?? 'Admin',
      applicants: List<String>.from(data['applicants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'type': type,
      'description': description,
      'postedBy': postedBy,
      'applicants': applicants,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
