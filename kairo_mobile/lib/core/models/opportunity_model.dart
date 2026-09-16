import 'package:cloud_firestore/cloud_firestore.dart';

class OpportunityModel {
  final String id;
  final String title;
  final String company;
  final String? imageUrl;
  final String location;
  final String type; // Stage, Emploi, Bourse, Concours
  final String description;
  final String postedBy; // User ID of the student/recruiter who posted
  final List<String> applicants; // IDs of users who applied
  final List<String> mandatorySkills;
  final String status;
  
  // ATS Fields
  final List<String> requiredDocuments;
  final String? educationLevel;
  final int? minExperience;
  final List<String> niceToHaveSkills;
  final List<String> languages;
  final List<String> preSelectionQuestions;
  final String? salaryRange;
  final String? department;
  final int? numberOfPositions;
  final String? workTime;
  final String? seniorityLevel;
  final String? remoteWork;
  
  final DateTime createdAt;
  final DateTime? closeDate;
  final DateTime? expectedStartDate;

  final String? applicationType;
  final String? externalLink;
  final List<String> tags;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.company,
    this.imageUrl,
    required this.location,
    required this.type,
    required this.description,
    required this.postedBy,
    this.applicants = const [],
    this.mandatorySkills = const [],
    this.status = 'ouvert',
    
    this.requiredDocuments = const [],
    this.educationLevel,
    this.minExperience,
    this.niceToHaveSkills = const [],
    this.languages = const [],
    this.preSelectionQuestions = const [],
    this.salaryRange,
    this.department,
    this.numberOfPositions,
    this.workTime,
    this.seniorityLevel,
    this.remoteWork,
    
    required this.createdAt,
    this.closeDate,
    this.expectedStartDate,
    this.applicationType,
    this.externalLink,
    this.tags = const [],
  });

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }
    
    DateTime? parseDateNullable(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }
    
    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    int? parseInt(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return OpportunityModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      company: data['company']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? data['companyLogoUrl']?.toString(),
      location: data['location']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Stage',
      description: data['description']?.toString() ?? '',
      postedBy: data['postedBy']?.toString() ?? 'Admin',
      applicants: parseList(data['applicants']),
      mandatorySkills: parseList(data['mandatorySkills']),
      status: data['status']?.toString() ?? 'ouvert',
      
      requiredDocuments: parseList(data['requiredDocuments']),
      educationLevel: data['educationLevel']?.toString(),
      minExperience: parseInt(data['minExperience']),
      niceToHaveSkills: parseList(data['niceToHaveSkills']),
      languages: parseList(data['languages']),
      preSelectionQuestions: parseList(data['preSelectionQuestions']),
      salaryRange: data['salaryRange']?.toString(),
      department: data['department']?.toString(),
      numberOfPositions: parseInt(data['numberOfPositions']),
      workTime: data['workTime']?.toString(),
      seniorityLevel: data['seniorityLevel']?.toString(),
      remoteWork: data['remoteWork']?.toString(),
      
      createdAt: parseDate(data['createdAt']),
      closeDate: parseDateNullable(data['closeDate']),
      expectedStartDate: parseDateNullable(data['expectedStartDate']),
      applicationType: data['applicationType']?.toString() ?? 'internal_ats',
      externalLink: data['externalLink']?.toString(),
      tags: parseList(data['tags']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'imageUrl': imageUrl,
      'location': location,
      'type': type,
      'description': description,
      'postedBy': postedBy,
      'applicants': applicants,
      'mandatorySkills': mandatorySkills,
      'status': status,
      
      'requiredDocuments': requiredDocuments,
      'educationLevel': educationLevel,
      'minExperience': minExperience,
      'niceToHaveSkills': niceToHaveSkills,
      'languages': languages,
      'preSelectionQuestions': preSelectionQuestions,
      'salaryRange': salaryRange,
      'department': department,
      'numberOfPositions': numberOfPositions,
      'workTime': workTime,
      'seniorityLevel': seniorityLevel,
      'remoteWork': remoteWork,
      
      'createdAt': Timestamp.fromDate(createdAt),
      'closeDate': closeDate != null ? Timestamp.fromDate(closeDate!) : null,
      'expectedStartDate': expectedStartDate != null ? Timestamp.fromDate(expectedStartDate!) : null,
      'applicationType': applicationType,
      'externalLink': externalLink,
      'tags': tags,
    };
  }
}
