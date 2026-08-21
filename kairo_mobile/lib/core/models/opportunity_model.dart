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
    return OpportunityModel(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      imageUrl: data['imageUrl'] ?? data['companyLogoUrl'],
      location: data['location'] ?? '',
      type: data['type'] ?? 'Stage',
      description: data['description'] ?? '',
      postedBy: data['postedBy'] ?? 'Admin',
      applicants: List<String>.from(data['applicants'] ?? []),
      mandatorySkills: List<String>.from(data['mandatorySkills'] ?? []),
      status: data['status'] ?? 'ouvert',
      
      requiredDocuments: List<String>.from(data['requiredDocuments'] ?? []),
      educationLevel: data['educationLevel'],
      minExperience: data['minExperience'],
      niceToHaveSkills: List<String>.from(data['niceToHaveSkills'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      preSelectionQuestions: List<String>.from(data['preSelectionQuestions'] ?? []),
      salaryRange: data['salaryRange'],
      department: data['department'],
      numberOfPositions: data['numberOfPositions'],
      workTime: data['workTime'],
      seniorityLevel: data['seniorityLevel'],
      remoteWork: data['remoteWork'],
      
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closeDate: (data['closeDate'] as Timestamp?)?.toDate(),
      expectedStartDate: (data['expectedStartDate'] as Timestamp?)?.toDate(),
      applicationType: data['applicationType'] ?? 'internal_ats',
      externalLink: data['externalLink'],
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
