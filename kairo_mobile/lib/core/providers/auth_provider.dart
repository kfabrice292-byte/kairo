import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
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
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await fetchUserData(user.uid);
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data();
        _userModel = UserModel.fromFirestore(doc);
      } else {
        _userData = {'name': currentUser?.displayName ?? 'Utilisateur', 'email': currentUser?.email};
        _userModel = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _userData = {'name': currentUser?.displayName ?? 'Utilisateur', 'email': currentUser?.email};
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
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await fetchUserData(userCredential.user!.uid);
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
          'skills': <String>[],
          'interests': <String>[],
          'portfolioLinks': <String>[],
          'createdAt': DateTime.now().toIso8601String(),
        };
        await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser);
      }
      await fetchUserData(uid);
      
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
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
        'skills': <String>[],
        'interests': <String>[],
        'portfolioLinks': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser);
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
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
        await fetchUserData(user.uid);
      } catch (e) {
        debugPrint('Error updating profile: $e');
        throw Exception("Erreur Firebase : $e");
      }
    }
  }

  Future<void> sendNetworkRequest(String otherUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == otherUserId) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final myRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(myRef, {
        'sentRequests': FieldValue.arrayUnion([otherUserId])
      });

      final otherRef = FirebaseFirestore.instance.collection('users').doc(otherUserId);
      batch.update(otherRef, {
        'receivedRequests': FieldValue.arrayUnion([user.uid])
      });

      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': otherUserId,
        'title': 'Invitation reçue',
        'body': '${_userModel?.name ?? "Quelqu'un"} souhaite vous ajouter à son réseau.',
        'type': 'network',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': user.uid,
      });

      await batch.commit();
      await fetchUserData(user.uid);
    } catch (e) {
      debugPrint('Error sending network request: $e');
    }
  }

  Future<void> acceptNetworkRequest(String otherUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == otherUserId) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final myRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(myRef, {
        'receivedRequests': FieldValue.arrayRemove([otherUserId]),
        'connections': FieldValue.arrayUnion([otherUserId])
      });

      final otherRef = FirebaseFirestore.instance.collection('users').doc(otherUserId);
      batch.update(otherRef, {
        'sentRequests': FieldValue.arrayRemove([user.uid]),
        'connections': FieldValue.arrayUnion([user.uid])
      });

      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': otherUserId,
        'title': 'Invitation acceptée',
        'body': '${_userModel?.name ?? "Quelqu'un"} a accepté votre invitation.',
        'type': 'network_accepted',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': user.uid,
      });

      await batch.commit();
      await fetchUserData(user.uid);
    } catch (e) {
      debugPrint('Error accepting network request: $e');
    }
  }

  Future<void> cancelOrRejectNetworkRequest(String otherUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid == otherUserId) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final myRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(myRef, {
        'sentRequests': FieldValue.arrayRemove([otherUserId]),
        'receivedRequests': FieldValue.arrayRemove([otherUserId])
      });

      final otherRef = FirebaseFirestore.instance.collection('users').doc(otherUserId);
      batch.update(otherRef, {
        'receivedRequests': FieldValue.arrayRemove([user.uid]),
        'sentRequests': FieldValue.arrayRemove([user.uid])
      });

      await batch.commit();
      await fetchUserData(user.uid);
    } catch (e) {
      debugPrint('Error cancelling network request: $e');
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

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Utilisateur non connecté.";
      
      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
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

  Future<String?> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "Utilisateur non connecté.";

      // Delete from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
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
