import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/kairo_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _jobTitleController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final jobTitle = _jobTitleController.text.trim();
    final skillsText = _skillsController.text.trim();
    
    List<Map<String, dynamic>> skills = [];
    if (skillsText.isNotEmpty) {
      final skillNames = skillsText.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      for (var s in skillNames) {
        skills.add({'name': s, 'level': 'Intermédiaire'});
      }
    }

    Map<String, dynamic> updateData = {};
    if (jobTitle.isNotEmpty) updateData['jobTitle'] = jobTitle;
    if (skills.isNotEmpty) {
      final currentSkills = auth.userModel?.skills.map((s) => s.toMap()).toList() ?? [];
      updateData['skills'] = [...currentSkills, ...skills];
    }
    
    if (updateData.isNotEmpty) {
      await auth.updateProfile(updateData);
    }
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      context.go('/main');
    }
  }

  void _skipSetup() {
    context.go('/main');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipSetup,
            child: Text(
              "Plus tard",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage >= index
                            ? AppColors.primary
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _currentPage == 2 ? "Terminer" : "Continuer",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.briefcase(), size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            "Quel est votre rôle ?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Indiquez le métier ou le poste que vous occupez, ou celui que vous visez.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          KairoTextField(
            controller: _jobTitleController,
            hintText: "Ex: Développeur Flutter, UI/UX Designer...",
            prefixIcon: PhosphorIcons.briefcase(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.lightning(), size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            "Vos compétences clés",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Ajoutez quelques compétences (séparées par des virgules) pour que l'IA vous propose les meilleures opportunités.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          KairoTextField(
            controller: _skillsController,
            hintText: "Ex: Figma, Dart, Gestion de projet...",
            prefixIcon: PhosphorIcons.star(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.filePdf(), size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text(
            "Avez-vous un CV ?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Bientôt, vous pourrez uploader votre CV et Kaïro remplira automatiquement votre profil !",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(PhosphorIcons.uploadSimple(), size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Fonctionnalité d'upload à venir",
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
