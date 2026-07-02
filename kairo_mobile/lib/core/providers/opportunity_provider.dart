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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _opportunities = snapshot.docs.map((doc) => OpportunityModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error fetching opportunities: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addOpportunity(OpportunityModel opp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await FirebaseFirestore.instance.collection('opportunities').add(opp.toMap());
  }
}
