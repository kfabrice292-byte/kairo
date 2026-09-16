// File generated as a template by AI.
// IMPORTANT: Remplacez ce fichier par le vrai fichier généré via la commande :
// flutterfire configure
// Cela liera votre projet Flutter Web à votre vrai projet Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REMPLACEZ_PAR_VOTRE_API_KEY_WEB',
    appId: 'REMPLACEZ_PAR_VOTRE_APP_ID_WEB',
    messagingSenderId: 'REMPLACEZ_PAR_VOTRE_SENDER_ID',
    projectId: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID',
    authDomain: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACEZ_PAR_VOTRE_API_KEY_ANDROID',
    appId: 'REMPLACEZ_PAR_VOTRE_APP_ID_ANDROID',
    messagingSenderId: 'REMPLACEZ_PAR_VOTRE_SENDER_ID',
    projectId: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID',
    storageBucket: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACEZ_PAR_VOTRE_API_KEY_IOS',
    appId: 'REMPLACEZ_PAR_VOTRE_APP_ID_IOS',
    messagingSenderId: 'REMPLACEZ_PAR_VOTRE_SENDER_ID',
    projectId: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID',
    storageBucket: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.kairoProWeb',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REMPLACEZ_PAR_VOTRE_API_KEY_MACOS',
    appId: 'REMPLACEZ_PAR_VOTRE_APP_ID_MACOS',
    messagingSenderId: 'REMPLACEZ_PAR_VOTRE_SENDER_ID',
    projectId: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID',
    storageBucket: 'REMPLACEZ_PAR_VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.kairoProWeb.RunnerTests',
  );
}
