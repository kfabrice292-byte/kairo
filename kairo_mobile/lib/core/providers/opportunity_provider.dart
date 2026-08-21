import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../main.dart' as import_main;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/opportunity_model.dart';
import '../models/user_model.dart';
import '../services/push_notification_service.dart';
import 'auth_provider.dart';

class OpportunityProvider extends ChangeNotifier {
  List<OpportunityModel> _opportunities = [];
  List<String> _savedOpportunities = [];
  Map<String, String> _applicationStatuses = {};
  Map<String, int> _matchScores = {};

  List<OpportunityModel> get opportunities => _opportunities;
  List<String> get savedOpportunities => _savedOpportunities;
  Map<String, String> get applicationStatuses => _applicationStatuses;
  Map<String, int> get matchScores => _matchScores;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  StreamSubscription? _authSub;
  StreamSubscription? _newOppSub;
  StreamSubscription? _userSub;
  StreamSubscription? _applicationsSub;

  OpportunityProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _cancelSubscriptions();
        _opportunities.clear();
        _savedOpportunities.clear();
        _applicationStatuses.clear();
        _matchScores.clear();
        notifyListeners();
      } else {
        _listenToOpportunities();
        _listenToUserData(user.uid);
        _listenToNewOpportunities(user.uid);
      }
    });
  }

  void _cancelSubscriptions() {
    _newOppSub?.cancel();
    _newOppSub = null;
    _userSub?.cancel();
    _userSub = null;
    _applicationsSub?.cancel();
    _applicationsSub = null;
  }

  
  DateTime _appStartTime = DateTime.now();

  void _listenToNewOpportunities(String userId) {
    _newOppSub?.cancel();
    
    // Listen to new opportunities added after app start
    _newOppSub = FirebaseFirestore.instance
        .collection('opportunities')
        .where('createdAt', isGreaterThan: _appStartTime)
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final opp = OpportunityModel.fromFirestore(change.doc);
              
              // Get current user to check tags
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
              if (userDoc.exists) {
                final userTags = List<String>.from(userDoc.data()?['tags'] ?? []);
                
                // Check for intersection
                if (userTags.any((tag) => opp.tags.contains(tag))) {
                  // PushNotificationService removed or use actual method
                  debugPrint('Notification for matching opportunity: ${opp.title}');
                }
              }
            }
          }
        });
  }


  void _listenToUserData(String userId) {
    _userSub?.cancel();
    _applicationsSub?.cancel();

    // Listen to saved opportunities
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            _savedOpportunities = List<String>.from(
              doc.data()?['savedOpportunities'] ?? [],
            );
            notifyListeners();
          }
        });

    // Listen to applications
    _applicationsSub = FirebaseFirestore.instance
        .collection('applications')
        .where('candidateId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          final statuses = <String, String>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            statuses[data['jobId']] = data['status'] ?? 'Envoyée';
          }
          _applicationStatuses = statuses;
          notifyListeners();
        });
  }

  Future<void> toggleSaveOpportunity(String oppId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté.");

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      if (_savedOpportunities.contains(oppId)) {
        await docRef.update({
          'savedOpportunities': FieldValue.arrayRemove([oppId]),
        });
      } else {
        await docRef.update({
          'savedOpportunities': FieldValue.arrayUnion([oppId]),
        });
      }
    } catch (e) {
      debugPrint('Error toggling save opportunity: $e');
      import_main.rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Erreur réseau. Action annulée."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  static const int _pageSize = 15;

  bool get hasMore => _hasMore;

  void _listenToOpportunities() {
    loadOpportunities(refresh: true);
  }

  Future<void> loadOpportunities({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    if (refresh) {
      _isLoading = true;
      _hasMore = true;
      _lastDocument = null;
      _opportunities.clear();
      _matchScores.clear();
      notifyListeners();
    } else {
      _isLoading = true; // or introduce _isLoadingMore
      notifyListeners();
    }

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      UserModel? userModel;
      
      if (authUser != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(authUser.uid)
              .get();
          if (userDoc.exists) {
            userModel = UserModel.fromFirestore(userDoc);
          }
        } catch (e) {
          debugPrint('Could not fetch user model: $e');
        }
      }

      bool usedRecommendations = false;
      List<DocumentSnapshot> recommendationDocs = [];

      if (authUser != null) {
        // Try fetching from backend recommendations engine
        Query query = FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .collection('recommendations')
            .orderBy('score', descending: true)
            .limit(_pageSize);
            
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        final recSnapshot = await query.get();
        if (recSnapshot.docs.isNotEmpty) {
          usedRecommendations = true;
          recommendationDocs = recSnapshot.docs;
          _lastDocument = recSnapshot.docs.last;
          _hasMore = recSnapshot.docs.length >= _pageSize;
        }
      }

      List<OpportunityModel> fetchedOpps = [];
      final Map<String, int> newScores = {};

      if (usedRecommendations) {
        // Fetch actual opportunity data for the recommendations
        for (var recDoc in recommendationDocs) {
          final data = recDoc.data() as Map<String, dynamic>;
          final oppId = data['opportunityId'] as String?;
          final score = data['score'] as int? ?? 0;
          if (oppId == null) continue;

          final oppDoc = await FirebaseFirestore.instance.collection('opportunities').doc(oppId).get();
          if (oppDoc.exists) {
            final opp = OpportunityModel.fromFirestore(oppDoc);
            if (opp.status == 'ouvert') {
              fetchedOpps.add(opp);
              newScores[opp.id] = score;
            }
          }
        }
      } else {
        // Fallback: fetch from global opportunities collection
        Query query = FirebaseFirestore.instance
            .collection('opportunities')
            .where('status', isEqualTo: 'ouvert')
            .limit(_pageSize);
        
        if (_lastDocument != null) {
          query = query.startAfterDocument(_lastDocument!);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
          _hasMore = snapshot.docs.length >= _pageSize;
          
          fetchedOpps = snapshot.docs
              .map((doc) => OpportunityModel.fromFirestore(doc))
              .toList();

          fetchedOpps.sort((a, b) {
            int scoreA = _calculateMatchScore(a, userModel);
            int scoreB = _calculateMatchScore(b, userModel);
            
            newScores[a.id] = scoreA;
            newScores[b.id] = scoreB;

            if (scoreA != scoreB) {
              return scoreB.compareTo(scoreA); // Descending score
            }
            return b.createdAt.compareTo(a.createdAt); // Then newest
          });
        } else {
          _hasMore = false;
        }
      }

      if (refresh) {
        _opportunities = fetchedOpps;
        _matchScores = newScores;
      } else {
        _opportunities.addAll(fetchedOpps);
        _matchScores.addAll(newScores);
      }

    } catch (e) {
      debugPrint('Error fetching opportunities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOpportunities() async {
    await loadOpportunities(refresh: false);
  }

  int _calculateMatchScore(OpportunityModel opp, UserModel? user) {
    if (user == null) return 0;
    int score = 0;

    // 1. Mandatory Skills (40% weight)
    if (opp.mandatorySkills.isNotEmpty) {
      int matches = 0;
      final userSkills = user.skills.map((s) => s.name.toLowerCase()).toList();
      for (String skill in opp.mandatorySkills) {
        if (userSkills.contains(skill.toLowerCase())) matches++;
      }
      score += (matches / opp.mandatorySkills.length * 40).round();
    } else {
      score += 20; // Default if no mandatory skills
    }

    // 2. Field of Study / Title Match (30% weight)
    final userField = user.fieldOfStudy.toLowerCase();
    final userTitle = user.professionalTitle.toLowerCase();
    final oppTitle = opp.title.toLowerCase();
    final oppDept = (opp.department ?? '').toLowerCase();
    
    if (userField.isNotEmpty && (oppTitle.contains(userField) || oppDept.contains(userField))) {
      score += 30;
    } else if (userTitle.isNotEmpty && (oppTitle.contains(userTitle) || oppDept.contains(userTitle))) {
      score += 20;
    } else {
      score += 10;
    }

    // 3. Tags / Interests (15% weight)
    if (opp.tags.isNotEmpty && user.tags.isNotEmpty) {
      int tagMatches = 0;
      final userTags = user.tags.map((t) => t.toLowerCase()).toList();
      for (String tag in opp.tags) {
        if (userTags.contains(tag.toLowerCase())) tagMatches++;
      }
      score += (tagMatches / opp.tags.length * 15).round();
    } else {
      score += 5;
    }

    // 4. Location / City (15% weight)
    final oppLocation = opp.location.toLowerCase();
    if (oppLocation.contains('remote') || oppLocation.contains('télétravail')) {
      score += 15;
    } else if (user.city.isNotEmpty && oppLocation.contains(user.city.toLowerCase())) {
      score += 15;
    } else if (user.country.isNotEmpty && oppLocation.contains(user.country.toLowerCase())) {
      score += 10;
    } else {
      score += 5;
    }

    return score > 100 ? 100 : score;
  }

  Future<String> addOpportunity(OpportunityModel opp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté.");

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('opportunities')
          .add(opp.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding opportunity: $e');
      throw Exception('Erreur lors de la création de l\'opportunité : $e');
    }
  }

  Future<String?> applyToOpportunity(String oppId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté.");

    try {
      // 1. Fetch user profile to embed in application
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      // Check if it is an external opportunity
      final oppDoc = await FirebaseFirestore.instance.collection('opportunities').doc(oppId).get();
      final oppData = oppDoc.data() ?? {};
      if (oppData['applicationType'] == 'external') {
        return oppData['externalLink'];
      }

      // 2. Add applicant ID to the opportunity array (legacy/mobile view)
      await FirebaseFirestore.instance
          .collection('opportunities')
          .doc(oppId)
          .update({
            'applicants': FieldValue.arrayUnion([user.uid]),
          });

      // 3. Create document in 'applications' collection for Kaïro Recruit Pro Kanban Pipeline
      // Create a talent profile map as expected by Recruit Pro
      final candidateProfile = {
        'id': user.uid,
        'name': userData['fullName'] ?? userData['name'] ?? 'Candidat Anonyme',
        'email': user.email ?? userData['email'] ?? '',
        'photoUrl': userData['photoUrl'] ?? userData['avatarUrl'] ?? '',
        'headline':
            userData['jobTitle'] ??
            userData['headline'] ??
            'Ajouter un titre professionnel',
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
      throw Exception('Erreur lors de la candidature : $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelSubscriptions();
    super.dispose();
  }
}
