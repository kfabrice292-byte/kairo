import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';
import '../models/user_model.dart';
import '../services/push_notification_service.dart';
import '../services/activity_logger_service.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  UserModel? _userModel;

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
  bool get isLoading => _isLoading;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? get userData => _userData;
  UserModel? get userModel => _userModel;

  AuthProvider() {
    _initAuthListener();
    WidgetsBinding.instance.addObserver(this);
  }

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _userSubscription?.cancel();
      if (user != null) {
        await fetchUserData(user.uid);
        await PushNotificationService.updateToken();
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
              if (doc.exists) {
                _userData = doc.data();
                _userModel = UserModel.fromFirestore(doc);
                notifyListeners();
              }
            });
      } else {
        _userData = null;
        _userModel = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && currentUser != null) {
      // Refresh user data when app resumes (e.g. after returning from HTech Pay browser checkout)
      fetchUserData(currentUser!.uid);
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userData = doc.data();
        _userModel = UserModel.fromFirestore(doc);
      } else {
        _userData = {
          'name': currentUser?.displayName ?? 'Utilisateur',
          'email': currentUser?.email,
        };
        _userModel = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _userData = {
        'name': currentUser?.displayName ?? 'Utilisateur',
        'email': currentUser?.email,
      };
      _userModel = null;
      notifyListeners();
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Aucun compte trouvé avec cet email.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'invalid-email':
        return "Adresse email invalide.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'email-already-in-use':
        return "Un compte existe déjà avec cet email.";
      case 'weak-password':
        return "Le mot de passe doit contenir au moins 6 caractères.";
      case 'operation-not-allowed':
        return "Ce mode de connexion n'est pas activé sur le serveur.";
      case 'network-request-failed':
        return "Erreur réseau. Vérifiez votre connexion internet.";
      default:
        return "Une erreur est survenue (${e.code}).";
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData(userCredential.user!.uid);
      
      await ActivityLoggerService.logAction(actionType: ActivityLoggerService.ACTION_LOGIN, metadata: {'method': 'email'});

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return "Une erreur inattendue est survenue.";
    }
  }

  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return "Connexion annulée par l'utilisateur.";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) {
        final newUser = {
          'name': userCredential.user!.displayName ?? 'Utilisateur',
          'email': userCredential.user!.email,
          'photoURL': userCredential.user!.photoURL,
          'points': 1000,
          'history': [],
          'university': '',
          'fieldOfStudy': '',
          'level': '',
          'country': '',
          'skills': [],
          'interests': <String>[],
          'languages': [],
          'certifications': [],
          'portfolioProjects': [],
          'portfolioLinks': <String>[],
          'createdAt': DateTime.now().toIso8601String(),
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(newUser);
      }
      await fetchUserData(uid);

      await ActivityLoggerService.logAction(actionType: ActivityLoggerService.ACTION_LOGIN, metadata: {'method': 'google'});

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return "Erreur Google Sign-In. (Avez-vous configuré la clé SHA-1 ?)";
    }
  }

  Future<String?> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      final newUser = {
        'name': name,
        'email': email,
        'points': 1000,
        'history': [],
        'photoURL': null,
        'university': '',
        'fieldOfStudy': '',
        'level': '',
        'country': '',
        'skills': [],
        'interests': <String>[],
        'languages': [],
        'certifications': [],
        'portfolioProjects': [],
        'portfolioLinks': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser);
      await fetchUserData(uid);

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      debugPrint('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return "Une erreur inattendue est survenue.";
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);
    await fetchUserData(user.uid);
  }

  Future<void> requestVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'pendingVerification': true});
        await fetchUserData(user.uid);
      } catch (e) {
        debugPrint('Error requesting verification: $e');
        throw Exception("Erreur Firebase : $e");
      }
    }
  }

  Future<void> addExperience(Experience exp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedExperiences = List<Experience>.from(_userModel!.experiences)
        ..add(exp);
      await updateProfile({
        'experiences': updatedExperiences.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error adding experience: $e');
      throw Exception("Erreur ajout expérience : $e");
    }
  }

  Future<void> updateExperience(Experience exp) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedExperiences = _userModel!.experiences
          .map((e) => e.id == exp.id ? exp : e)
          .toList();
      await updateProfile({
        'experiences': updatedExperiences.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error updating experience: $e');
      throw Exception("Erreur modification expérience : $e");
    }
  }

  Future<void> deleteExperience(String expId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedExperiences = _userModel!.experiences
          .where((e) => e.id != expId)
          .toList();
      await updateProfile({
        'experiences': updatedExperiences.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error deleting experience: $e');
      throw Exception("Erreur suppression expérience : $e");
    }
  }

  Future<void> addEducation(Education edu) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedEducations = List<Education>.from(_userModel!.educations)
        ..add(edu);
      await updateProfile({
        'educations': updatedEducations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error adding education: $e');
      throw Exception("Erreur ajout formation : $e");
    }
  }

  Future<void> updateEducation(Education edu) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedEducations = _userModel!.educations
          .map((e) => e.id == edu.id ? edu : e)
          .toList();
      await updateProfile({
        'educations': updatedEducations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error updating education: $e');
      throw Exception("Erreur modification formation : $e");
    }
  }

  Future<void> deleteEducation(String eduId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedEducations = _userModel!.educations
          .where((e) => e.id != eduId)
          .toList();
      await updateProfile({
        'educations': updatedEducations.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error deleting education: $e');
      throw Exception("Erreur suppression formation : $e");
    }
  }

  Future<void> deleteSkill(String skillName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedSkills = _userModel!.skills
          .where((s) => s.name != skillName)
          .toList();
      await updateProfile({
        'skills': updatedSkills.map((s) => s.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error deleting skill: $e');
      throw Exception("Erreur suppression compétence : $e");
    }
  }

  Future<void> deleteLanguage(String langName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedLanguages = _userModel!.languages
          .where((l) => l.name != langName)
          .toList();
      await updateProfile({
        'languages': updatedLanguages.map((l) => l.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error deleting language: $e');
      throw Exception("Erreur suppression langue : $e");
    }
  }

  Future<void> deleteInterest(String interest) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedInterests = _userModel!.interests
          .where((i) => i != interest)
          .toList();
      await updateProfile({
        'interests': updatedInterests,
      });
    } catch (e) {
      debugPrint('Error deleting interest: $e');
      throw Exception("Erreur suppression intérêt : $e");
    }
  }

  Future<void> deletePortfolioProject(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final updatedProjects = _userModel!.portfolioProjects
          .where((p) => p.id != projectId)
          .toList();
      await updateProfile({
        'portfolioProjects': updatedProjects.map((p) => p.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Error deleting portfolio project: $e');
      throw Exception("Erreur suppression projet : $e");
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Une erreur inattendue est survenue.";
    }
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Utilisateur non connecté.";

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Une erreur inattendue est survenue.";
    }
  }

  Future<String?> changeEmail(String currentPassword, String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Utilisateur non connecté.";

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'email': newEmail},
      );
      await fetchUserData(user.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Une erreur inattendue est survenue.";
    }
  }

  Future<String?> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Utilisateur non connecté.";

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete from Auth
      await user.delete();

      _userData = null;
      _userModel = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Veuillez vous reconnecter avant de supprimer votre compte.";
      }
      return _getFirebaseErrorMessage(e);
    } catch (e) {
      return "Erreur lors de la suppression du compte.";
    }
  }
}
