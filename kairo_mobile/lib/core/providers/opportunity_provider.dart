import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/opportunity_model.dart';

class OpportunityProvider extends ChangeNotifier {
  List<OpportunityModel> _opportunities = [];
  bool _isLoading = false;

  List<OpportunityModel> get opportunities => _opportunities;
  bool get isLoading => _isLoading;

  OpportunityProvider() {
    _listenToOpportunities();
  }

  void _listenToOpportunities() {
    _isLoading = true;
    notifyListeners();

    FirebaseFirestore.instance
        .collection('opportunities')
        .where('status', isEqualTo: 'ouvert') // Only active jobs
        .snapshots()
        .listen((snapshot) async {
      
      final user = FirebaseAuth.instance.currentUser;
      List<String> userSkills = [];
      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          userSkills = List<String>.from(userDoc.data()?['skills'] ?? []);
        } catch (e) {
          debugPrint('Could not fetch user skills: $e');
        }
      }

      final List<OpportunityModel> fetchedOpps = snapshot.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();
      
      // Matching Algorithm : Score each opportunity
      final userSkillsStr = userSkills.join(' ').toLowerCase();
      
      fetchedOpps.sort((a, b) {
        int scoreA = _calculateMatchScore(a, userSkillsStr);
        int scoreB = _calculateMatchScore(b, userSkillsStr);
        
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Descending score
        }
        return b.createdAt.compareTo(a.createdAt); // Then newest
      });

      _opportunities = fetchedOpps;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching opportunities: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  int _calculateMatchScore(OpportunityModel opp, String userSkillsStr) {
    if (opp.mandatorySkills.isEmpty) return 0;
    int matches = 0;
    for (String skill in opp.mandatorySkills) {
      if (userSkillsStr.contains(skill.toLowerCase())) matches++;
    }
    return (matches / opp.mandatorySkills.length * 100).round();
  }

  Future<void> addOpportunity(OpportunityModel opp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('opportunities').add(opp.toMap());
  }

  Future<void> applyToOpportunity(String oppId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch user profile to embed in application
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // 2. Add applicant ID to the opportunity array (legacy/mobile view)
      await FirebaseFirestore.instance.collection('opportunities').doc(oppId).update({
        'applicants': FieldValue.arrayUnion([user.uid])
      });

      // 3. Create document in 'applications' collection for Kaïro Recruit Pro Kanban Pipeline
      // Create a talent profile map as expected by Recruit Pro
      final candidateProfile = {
        'id': user.uid,
        'name': userData['fullName'] ?? userData['name'] ?? 'Candidat Anonyme',
        'email': user.email ?? userData['email'] ?? '',
        'photoUrl': userData['photoUrl'] ?? userData['avatarUrl'] ?? '',
        'headline': userData['jobTitle'] ?? userData['headline'] ?? 'Étudiant',
        'bio': userData['bio'] ?? '',
        'skills': userData['skills'] ?? [],
        'university': userData['university'] ?? userData['school'] ?? '',
        'country': userData['location'] ?? userData['country'] ?? '',
      };

      await FirebaseFirestore.instance.collection('applications').add({
        'jobId': oppId,
        'candidateId': user.uid,
        'candidate': candidateProfile,
        'status': 'new', // appears in "À traiter" column in Kanban
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error applying to opportunity: $e');
    }
  }
}
