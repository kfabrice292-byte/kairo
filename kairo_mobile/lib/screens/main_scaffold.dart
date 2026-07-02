import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'feed_screen.dart';
import 'opportunities_screen.dart';
import 'projects_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const OpportunitiesScreen(),
    const ProjectsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.house()),
            activeIcon: Icon(PhosphorIcons.house()),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.briefcase()),
            activeIcon: Icon(PhosphorIcons.briefcase()),
            label: 'Opportunités',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.rocketLaunch()),
            activeIcon: Icon(PhosphorIcons.rocketLaunch()),
            label: 'Projets',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.user()),
            activeIcon: Icon(PhosphorIcons.user()),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
