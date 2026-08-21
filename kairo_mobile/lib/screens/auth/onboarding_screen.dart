import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Créer',
      'subtitle': 'Bâtissez votre identité numérique',
      'description':
          'Façonnez un profil unique, générez des CV sur-mesure et mettez en valeur votre parcours comme jamais auparavant.',
      'icon': Icon(PhosphorIcons.pencilLine(), size: 80),
    },
    {
      'title': 'Innover',
      'subtitle': 'Découvrez des projets',
      'description':
          'Explorez des idées novatrices, collaborez sur des projets open-source et poussez les limites de la technologie.',
      'icon': Icon(PhosphorIcons.lightbulb(), size: 80),
    },
    {
      'title': 'Connecter',
      'subtitle': 'Rejoignez la communauté',
      'description':
          'Échangez avec des experts, participez à des groupes d\'intérêt et créez des opportunités professionnelles infinies.',
      'icon': Icon(PhosphorIcons.graph(), size: 80),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  "Passer",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPageContent(_pages[index], theme);
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : theme.dividerColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Next / Start Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).iconTheme.color,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: _currentPage == _pages.length - 1 ? 24 : 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? "Commencer"
                              : "Suivant",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          Icon(PhosphorIcons.arrowRight(), size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(Map<String, dynamic> page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimalist Icon Illustration
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: IconTheme(
              data: IconThemeData(color: theme.textTheme.bodyLarge?.color),
              child: page['icon'] as Widget,
            ),
          ),
          const SizedBox(height: 60),

          // Text Content
          Text(
            page['title'] as String,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page['subtitle'] as String,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page['description'] as String,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
