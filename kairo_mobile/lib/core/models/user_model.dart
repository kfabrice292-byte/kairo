import 'package:cloud_firestore/cloud_firestore.dart';

class Language {
  final String name;
  final int level; // 1 to 5

  Language({required this.name, this.level = 3});

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      name: map['name'] ?? '',
      level: map['level'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'level': level};
  }
}

class Certification {
  final String name;
  final String issuer;
  final String date;
  final String url;

  Certification({
    required this.name,
    required this.issuer,
    this.date = '',
    this.url = '',
  });

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      name: map['name'] ?? '',
      issuer: map['issuer'] ?? '',
      date: map['date'] ?? '',
      url: map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'issuer': issuer, 'date': date, 'url': url};
  }
}

class PortfolioProject {
  final String id;
  final String title;
  final String description;
  final String result;
  final List<String> technologies;
  final String link;
  final String imageUrl;

  PortfolioProject({
    required this.id,
    required this.title,
    required this.description,
    this.result = '',
    this.technologies = const [],
    this.link = '',
    this.imageUrl = '',
  });

  factory PortfolioProject.fromMap(Map<String, dynamic> map) {
    return PortfolioProject(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      result: map['result'] ?? '',
      technologies: List<String>.from(map['technologies'] ?? []),
      link: map['link'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'result': result,
      'technologies': technologies,
      'link': link,
      'imageUrl': imageUrl,
    };
  }
}
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

class Education {
  final String id;
  final String title;
  final String institution;
  final String period;
  final String description;

  Education({
    required this.id,
    required this.title,
    required this.institution,
    required this.period,
    this.description = '',
  });

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      institution: map['institution'] ?? '',
      period: map['period'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'institution': institution,
      'period': period,
      'description': description,
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

  // Formations
  final List<Education> educations;

  // Projets (références ou résumé des projets auxquels on participe)
  final List<String> projectIds;
  
  // Projets de Portfolio (spécifiques au candidat)
  final List<PortfolioProject> portfolioProjects;

  // Certifications & Langues
  final List<Certification> certifications;
  final List<Language> languages;
  final List<String> interests;

  // Portfolio & Documents (liens d'images, PDF, etc.)
  final List<String> portfolioLinks;
  final List<String> documents; // CV, certificats
  final String videoPitchUrl; // Pitch vidéo 60s

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
  final List<String> followers;
  final List<String> following;
  final List<String> savedOpportunities;

  // CV Builder Data
  final String lastCvTitle;
  final List<String> tags;
  final String lastCvBio;
  final String lastCvTemplate;

  final bool isVerified;
  final bool pendingVerification;
  final bool isPremium; // Computed: true if raw isPremium is true AND premiumUntil is valid
  final DateTime? premiumUntil;
  final int cvCredits;
  final String role; // Legacy field
  final Map<String, String> roles; // Multi-tenant RBAC: { "orgId": "ADMIN" }
  final String subscriptionStatus; // FREE, PREMIUM_PAID, PREMIUM_GIFT, PREMIUM_CODE, PREMIUM_ADMIN, BANNED

  bool get isAdmin => role == 'admin' || roles.containsValue('ADMIN') || roles.containsValue('SUPER_ADMIN');
  bool get isBanned => subscriptionStatus == 'BANNED';
  
  // Helper for multi-tenant check
  bool hasRoleInOrg(String orgId, List<String> allowedRoles) {
    if (roles.containsKey(orgId)) {
      return allowedRoles.contains(roles[orgId]);
    }
    return false;
  }

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
    this.educations = const [],
    this.projectIds = const [],
    this.portfolioProjects = const [],
    this.certifications = const [],
    this.languages = const [],
    this.interests = const [],
    this.portfolioLinks = const [],
    this.documents = const [],
    this.videoPitchUrl = '',
    this.phone = '',
    this.email = '',
    this.linkedin = '',
    this.github = '',
    this.behance = '',
    this.website = '',
    this.savedPosts = const [],
    this.followers = const [],
    this.following = const [],
    this.savedOpportunities = const [],
    this.lastCvTitle = '',
    this.tags = const [],
    this.lastCvBio = '',
    this.lastCvTemplate = 'moderne',
    this.isVerified = false,
    this.pendingVerification = false,
    this.isPremium = false,
    this.premiumUntil,
    this.cvCredits = 0,
    this.role = 'user',
    this.roles = const {},
    this.subscriptionStatus = 'FREE',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    // Calcul de l'abonnement actif
    bool rawPremium = data['isPremium'] ?? false;
    String status = data['subscriptionStatus'] ?? 'FREE';
    if (status != 'FREE' && status != 'BANNED') {
      rawPremium = true;
    }
    
    DateTime? pUntil;
    if (data['premiumUntil'] != null) {
      if (data['premiumUntil'] is Timestamp) {
        pUntil = (data['premiumUntil'] as Timestamp).toDate();
      } else if (data['premiumUntil'] is int) {
        pUntil = DateTime.fromMillisecondsSinceEpoch(data['premiumUntil'] as int);
      }
    }
    bool activePremium = rawPremium;
    if (rawPremium && pUntil != null) {
      activePremium = pUntil.isAfter(DateTime.now());
      if (!activePremium) {
        status = 'FREE'; // Si expiré
      }
    }

    return UserModel(
      uid: uid,
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
      educations: (data['educations'] as List<dynamic>? ?? [])
          .map((e) => Education.fromMap(e as Map<String, dynamic>))
          .toList(),
      projectIds: List<String>.from(data['projectIds'] ?? []),
      portfolioProjects: (data['portfolioProjects'] as List<dynamic>? ?? [])
          .map((e) => PortfolioProject.fromMap(e as Map<String, dynamic>))
          .toList(),
      certifications: (data['certifications'] as List<dynamic>? ?? [])
          .map((e) => Certification.fromMap(e as Map<String, dynamic>))
          .toList(),
      languages: (data['languages'] as List<dynamic>? ?? [])
          .map((e) => Language.fromMap(e as Map<String, dynamic>))
          .toList(),
      interests: List<String>.from(data['interests'] ?? []),
      portfolioLinks: List<String>.from(data['portfolioLinks'] ?? []),
      documents: List<String>.from(data['documents'] ?? []),
      videoPitchUrl: data['videoPitchUrl'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      linkedin: data['linkedin'] ?? '',
      github: data['github'] ?? '',
      behance: data['behance'] ?? '',
      website: data['website'] ?? '',
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      savedOpportunities: List<String>.from(data['savedOpportunities'] ?? []),
      lastCvTitle: data['lastCvTitle'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      lastCvBio: data['lastCvBio'] ?? '',
      lastCvTemplate: data['lastCvTemplate'] ?? 'moderne',
      isVerified: data['isVerified'] ?? false,
      pendingVerification: data['pendingVerification'] ?? false,
      isPremium: activePremium,
      premiumUntil: pUntil,
      cvCredits: data['cvCredits'] ?? 0,
      role: data['role'] ?? 'user',
      roles: Map<String, String>.from(data['roles'] ?? {}),
      subscriptionStatus: status,
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
      'educations': educations.map((e) => e.toMap()).toList(),
      'projectIds': projectIds,
      'portfolioProjects': portfolioProjects.map((p) => p.toMap()).toList(),
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'languages': languages.map((l) => l.toMap()).toList(),
      'interests': interests,
      'portfolioLinks': portfolioLinks,
      'documents': documents,
      'videoPitchUrl': videoPitchUrl,
      'phone': phone,
      'email': email,
      'linkedin': linkedin,
      'github': github,
      'behance': behance,
      'website': website,
      'savedPosts': savedPosts,
      'followers': followers,
      'following': following,
      'savedOpportunities': savedOpportunities,
      'lastCvTitle': lastCvTitle,
      'tags': tags,
      'lastCvBio': lastCvBio,
      'lastCvTemplate': lastCvTemplate,
      'isVerified': isVerified,
      'pendingVerification': pendingVerification,
      'isPremium': isPremium,
      'premiumUntil': premiumUntil,
      'cvCredits': cvCredits,
      'role': role,
      'roles': roles,
      'subscriptionStatus': subscriptionStatus,
    };
  }
}
