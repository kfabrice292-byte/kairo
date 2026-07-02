import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
  bool get isLoading => _isLoading;
  User? get currentUser => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? get userData => _userData;

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
      } else {
        _userData = {'name': currentUser?.displayName ?? 'Utilisateur', 'email': currentUser?.email};
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      _userData = {'name': currentUser?.displayName ?? 'Utilisateur', 'email': currentUser?.email};
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

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
