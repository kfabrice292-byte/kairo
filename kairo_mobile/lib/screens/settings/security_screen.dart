import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/kairo_text_field.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final _currentPasswordEmailController = TextEditingController();
  final _newEmailController = TextEditingController();
  bool _isLoadingEmail = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordEmailController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleChangeEmail() async {
    final current = _currentPasswordEmailController.text.trim();
    final newEmail = _newEmailController.text.trim();

    if (current.isEmpty || newEmail.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs.", true);
      return;
    }

    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _showSnackBar("Veuillez entrer une adresse email valide.", true);
      return;
    }

    setState(() => _isLoadingEmail = true);

    final auth = context.read<AuthProvider>();
    final error = await auth.changeEmail(current, newEmail);

    if (mounted) {
      setState(() => _isLoadingEmail = false);
      if (error == null) {
        _showSnackBar(
          "Email modifié avec succès. Un lien de vérification a été envoyé.",
          false,
        );
        _currentPasswordEmailController.clear();
        _newEmailController.clear();
      } else {
        _showSnackBar(error, true);
      }
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs.", true);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar(
        "Le nouveau mot de passe doit faire au moins 6 caractères.",
        true,
      );
      return;
    }

    if (newPass != confirm) {
      _showSnackBar("Les nouveaux mots de passe ne correspondent pas.", true);
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final error = await auth.changePassword(current, newPass);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        _showSnackBar("Mot de passe modifié avec succès.", false);
        Navigator.pop(context);
      } else {
        _showSnackBar(error, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sécurité',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Modifier votre mot de passe",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Assurez-vous de choisir un mot de passe fort et de ne pas le réutiliser.",
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            KairoTextField(
              controller: _currentPasswordController,
              hintText: 'Mot de passe actuel',
              prefixIcon: PhosphorIcons.lockKey(),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            KairoTextField(
              controller: _newPasswordController,
              hintText: 'Nouveau mot de passe',
              prefixIcon: PhosphorIcons.shieldCheck(),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            KairoTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirmer nouveau mot de passe',
              prefixIcon: PhosphorIcons.shieldCheck(),
              obscureText: true,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Text(
                      'Mettre à jour le mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 32),

            const Text(
              "Changer d'adresse email",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Un lien de vérification sera envoyé à la nouvelle adresse.",
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 32),

            KairoTextField(
              controller: _currentPasswordEmailController,
              hintText: 'Mot de passe actuel',
              prefixIcon: PhosphorIcons.lockKey(),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            KairoTextField(
              controller: _newEmailController,
              hintText: 'Nouvelle adresse email',
              prefixIcon: PhosphorIcons.envelopeSimple(),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoadingEmail ? null : _handleChangeEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor: AppColors.secondary.withValues(
                  alpha: 0.6,
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoadingEmail
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Mettre à jour l\'email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
