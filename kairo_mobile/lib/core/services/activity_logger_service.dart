import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ActivityLoggerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> logAction({
    required String actionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('activity_logs').add({
        'uid': user.uid,
        'actionType': actionType,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging activity: ');
    }
  }

  // Types d\'actions prédéfinis pour éviter les fautes de frappe
  static const String ACTION_LOGIN = 'LOGIN';
  static const String ACTION_GENERATE_CV = 'GENERATE_CV';
  static const String ACTION_GENERATE_LETTER = 'GENERATE_LETTER';
  static const String ACTION_GENERATE_PORTFOLIO = 'GENERATE_PORTFOLIO';
  static const String ACTION_DOWNLOAD_PDF = 'DOWNLOAD_PDF';
  static const String ACTION_UPDATE_PROFILE = 'UPDATE_PROFILE';
  static const String ACTION_BUY_DOCUMENT = 'BUY_DOCUMENT';
  static const String ACTION_SUBSCRIBE_PREMIUM = 'SUBSCRIBE_PREMIUM';
}
