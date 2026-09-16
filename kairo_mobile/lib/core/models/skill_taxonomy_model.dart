import 'package:cloud_firestore/cloud_firestore.dart';

class SkillTaxonomyModel {
  final String id;
  final String name; // Normalized name (e.g., "Flutter")
  final String category; // e.g., "Software Development"
  final String subcategory; // e.g., "Mobile Development"
  final List<String> aliases; // e.g., ["Flutter SDK", "flutter dev"]
  final List<String> relatedSkills; // e.g., ["Dart", "Mobile UI"]

  SkillTaxonomyModel({
    required this.id,
    required this.name,
    this.category = '',
    this.subcategory = '',
    this.aliases = const [],
    this.relatedSkills = const [],
  });

  factory SkillTaxonomyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return SkillTaxonomyModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      aliases: List<String>.from(data['aliases'] ?? []),
      relatedSkills: List<String>.from(data['relatedSkills'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'aliases': aliases,
      'relatedSkills': relatedSkills,
    };
  }
}
