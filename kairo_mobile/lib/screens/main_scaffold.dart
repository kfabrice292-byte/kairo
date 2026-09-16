import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'home_screen.dart';
import 'opportunities_screen.dart';
import 'portfolio_screen.dart';
import 'profile_screen.dart';
import 'publish/add_experience_dialog.dart';
import 'publish/add_project_dialog.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onTabTapped: (index) {
      setState(() {
        _currentIndex = index;
      });
    }),
    OpportunitiesScreen(),
    const PortfolioScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.house()),
            activeIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.briefcase()),
            activeIcon: Icon(PhosphorIcons.briefcase(PhosphorIconsStyle.fill)),
            label: 'Opportunités',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.userList()),
            activeIcon: Icon(PhosphorIcons.userList(PhosphorIconsStyle.fill)),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.user()),
            activeIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 2 || _currentIndex == 3)
          ? FloatingActionButton(
              onPressed: () {
                _showPublishModal(context);
              },
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showPublishModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Que souhaitez-vous publier ?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildPublishOption(
              context,
              icon: PhosphorIcons.briefcase(),
              title: 'Une expérience pro',
              subtitle: 'Enrichir votre parcours professionnel (CV)',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddExperienceDialog(),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPublishOption(
              context,
              icon: PhosphorIcons.rocketLaunch(),
              title: 'Un projet',
              subtitle:
                  'Présenter une réalisation ou chercher des collaborateurs',
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddProjectDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
