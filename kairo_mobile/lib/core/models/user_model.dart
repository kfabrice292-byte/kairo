import 'package:cloud_firestore/cloud_firestore.dart';

class Skill {
  final String name;
  final String level;

  Skill({required this.name, this.level = 'Intermédiaire'});

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] ?? '',
      level: map['level'] ?? 'Intermédiaire',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'level': level};
  }
}

class Experience {
  final String id;
  final String title;
  final String organization;
  final String period;
  final String description;
  final List<String> skillsUsed;

  Experience({
    required this.id,
    required this.title,
    required this.organization,
    required this.period,
    required this.description,
    this.skillsUsed = const [],
  });

  factory Experience.fromMap(Map<String, dynamic> map) {
    return Experience(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      organization: map['organization'] ?? '',
      period: map['period'] ?? '',
      description: map['description'] ?? '',
      skillsUsed: List<String>.from(map['skillsUsed'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'period': period,
      'description': description,
      'skillsUsed': skillsUsed,
    };
  }
}

class UserModel {
  final String uid;

  // Informations personnelles
  final String photoURL;
  final String coverPhoto;
  final String name; // Equivalent à Prénom + Nom
  final String professionalTitle;
  final String bio;
  final String country;
  final String city;
  final String university;
  final String establishment;
  final String fieldOfStudy;
  final String studyLevel;

  // Compétences
  final List<Skill> skills;

  // Expériences
  final List<Experience> experiences;

  // Projets (références ou résumé des projets auxquels on participe)
  // On stockera les IDs des projets ou un résumé
  final List<String> projectIds;

  // Portfolio & Documents (liens d'images, PDF, etc.)
  final List<String> portfolioLinks;
  final List<String> documents; // CV, certificats

  // Contacts
  final String phone;
  final String email;
  final String linkedin;
  final String github;
  final String behance;
  final String website;

  // Saved Posts (Bookmarks)
  final List<String> savedPosts;

  // Connections (Network)
  final List<String> connections;
  final List<String> sentRequests;
  final List<String> receivedRequests;
  final List<String> followers;
  final List<String> following;
  final List<String> savedOpportunities;

  // CV Builder Data
  final String lastCvTitle;
  final String lastCvBio;
  final String lastCvTemplate;

  UserModel({
    required this.uid,
    this.photoURL = '',
    this.coverPhoto = '',
    this.name = '',
    this.professionalTitle = '',
    this.bio = '',
    this.country = '',
    this.city = '',
    this.university = '',
    this.establishment = '',
    this.fieldOfStudy = '',
    this.studyLevel = '',
    this.skills = const [],
    this.experiences = const [],
    this.projectIds = const [],
    this.portfolioLinks = const [],
    this.documents = const [],
    this.phone = '',
    this.email = '',
    this.linkedin = '',
    this.github = '',
    this.behance = '',
    this.website = '',
    this.savedPosts = const [],
    this.connections = const [],
    this.sentRequests = const [],
    this.receivedRequests = const [],
    this.followers = const [],
    this.following = const [],
    this.savedOpportunities = const [],
    this.lastCvTitle = '',
    this.lastCvBio = '',
    this.lastCvTemplate = 'moderne',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      photoURL: data['photoURL'] ?? '',
      coverPhoto: data['coverPhoto'] ?? '',
      name: data['name'] ?? '',
      professionalTitle: data['professionalTitle'] ?? '',
      bio: data['bio'] ?? '',
      country: data['country'] ?? '',
      city: data['city'] ?? '',
      university: data['university'] ?? '',
      establishment: data['establishment'] ?? '',
      fieldOfStudy: data['fieldOfStudy'] ?? '',
      studyLevel: data['studyLevel'] ?? '',
      skills: (data['skills'] as List<dynamic>? ?? [])
          .map((e) {
            if (e is String) return Skill(name: e);
            if (e is Map<String, dynamic>) return Skill.fromMap(e);
            return Skill(name: '');
          })
          .where((s) => s.name.isNotEmpty)
          .toList(),
      experiences: (data['experiences'] as List<dynamic>? ?? [])
          .map((e) => Experience.fromMap(e as Map<String, dynamic>))
          .toList(),
      projectIds: List<String>.from(data['projectIds'] ?? []),
      portfolioLinks: List<String>.from(data['portfolioLinks'] ?? []),
      documents: List<String>.from(data['documents'] ?? []),
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      linkedin: data['linkedin'] ?? '',
      github: data['github'] ?? '',
      behance: data['behance'] ?? '',
      website: data['website'] ?? '',
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      connections: List<String>.from(data['connections'] ?? []),
      sentRequests: List<String>.from(data['sentRequests'] ?? []),
      receivedRequests: List<String>.from(data['receivedRequests'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      savedOpportunities: List<String>.from(data['savedOpportunities'] ?? []),
      lastCvTitle: data['lastCvTitle'] ?? '',
      lastCvBio: data['lastCvBio'] ?? '',
      lastCvTemplate: data['lastCvTemplate'] ?? 'moderne',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photoURL': photoURL,
      'coverPhoto': coverPhoto,
      'name': name,
      'professionalTitle': professionalTitle,
      'bio': bio,
      'country': country,
      'city': city,
      'university': university,
      'establishment': establishment,
      'fieldOfStudy': fieldOfStudy,
      'studyLevel': studyLevel,
      'skills': skills.map((s) => s.toMap()).toList(),
      'experiences': experiences.map((e) => e.toMap()).toList(),
      'projectIds': projectIds,
      'portfolioLinks': portfolioLinks,
      'documents': documents,
      'phone': phone,
      'email': email,
      'linkedin': linkedin,
      'github': github,
      'behance': behance,
      'website': website,
      'savedPosts': savedPosts,
      'connections': connections,
      'sentRequests': sentRequests,
      'receivedRequests': receivedRequests,
      'followers': followers,
      'following': following,
      'savedOpportunities': savedOpportunities,
      'lastCvTitle': lastCvTitle,
      'lastCvBio': lastCvBio,
      'lastCvTemplate': lastCvTemplate,
    };
  }
}
