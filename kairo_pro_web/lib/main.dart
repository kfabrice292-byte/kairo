import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase non initialisé avec options. Exécutez flutterfire configure.');
  }

  runApp(const KairoProApp());
}

class KairoProApp extends StatelessWidget {
  const KairoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaïro Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: const Color(0xFF1E293B), // Slate 800
          displayColor: const Color(0xFF0F172A), // Slate 900
        ),
      ),
      // Auto-route based on auth state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.orange)),
            );
          }
          if (snapshot.hasData) {
            // L'utilisateur est authentifié, mais la vérification du RBAC 
            // devrait idéalement se faire via un Provider/Service global.
            // Pour simplifier l'exemple, on le route vers Dashboard.
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
