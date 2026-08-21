import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/ashtech_payment_dialog.dart';
import '../../core/services/activity_logger_service.dart';
import '../../core/theme/app_colors.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _processPayment() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AshtechPaymentDialog(
        user: user,
        paymentType: 'premium',
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement initié. Votre abonnement Premium sera débloqué automatiquement.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showPromoCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Code Promotionnel'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Saisissez votre code d\'activation Premium :'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: KAIROVIP...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  if (isSubmitting) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final code = codeController.text.trim().toUpperCase();
                    if (code.isEmpty) return;

                    setState(() => isSubmitting = true);
                    
                    try {
                      final query = await FirebaseFirestore.instance
                          .collection('promo_codes')
                          .where('code', isEqualTo: code)
                          .limit(1)
                          .get();

                      if (query.docs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code invalide.')));
                        setState(() => isSubmitting = false);
                        return;
                      }

                      final doc = query.docs.first;
                      final data = doc.data();
                      final type = data['type'] ?? 'SINGLE';
                      final currentUses = data['currentUses'] ?? 0;
                      final maxUses = data['maxUses'] ?? 0;
                      final durationDays = data['durationDays'] ?? 30;
                      final expiresAt = data['expiresAt'] as Timestamp?;

                      // Vérifications
                      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce code a expiré.')));
                        setState(() => isSubmitting = false);
                        return;
                      }

                      if (type != 'UNLIMITED' && currentUses >= maxUses) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce code a atteint sa limite d\'utilisation.')));
                        setState(() => isSubmitting = false);
                        return;
                      }

                      // Application du code
                      final user = context.read<AuthProvider>().userModel;
                      if (user != null) {
                        final batch = FirebaseFirestore.instance.batch();
                        
                        // Incrémenter l'utilisation du code
                        batch.update(doc.reference, {
                          'currentUses': FieldValue.increment(1)
                        });

                        // Mettre à jour l'utilisateur
                        final now = DateTime.now();
                        final until = now.add(Duration(days: durationDays));
                        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                        
                        batch.update(userRef, {
                          'isPremium': true,
                          'subscriptionStatus': 'PREMIUM_CODE',
                          'premiumSince': FieldValue.serverTimestamp(),
                          'premiumUntil': Timestamp.fromDate(until),
                        });

                        await batch.commit();

                        ActivityLoggerService.logAction(actionType: 'USE_PROMO_CODE', metadata: {'code': code});
                        
                        // Recharger l'utilisateur
                        await context.read<AuthProvider>().fetchUserData(user.uid);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code validé ! Vous êtes Premium.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                          Navigator.pop(context); // Quitter l'écran Premium
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la vérification.')));
                      setState(() => isSubmitting = false);
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Abonnement', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(PhosphorIcons.x(), color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Kaïro Pro',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Passez à la vitesse supérieure et maximisez vos chances.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Ce qui est inclus :',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      title: 'Génération de Documents',
                      description: 'CV, lettres et portfolios illimités.',
                    ),
                    _buildFeatureItem(
                      context,
                      title: 'Alertes Emploi Exclusives',
                      description: 'Soyez le premier informé des opportunités.',
                    ),
                    _buildFeatureItem(
                      context,
                      title: 'Scoring ATS & Analyse',
                      description: 'Optimisez votre CV pour les recruteurs.',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abonnement Mensuel', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Annulable à tout moment', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Text(
                        '1000 FCFA / mois',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'S\'abonner',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showPromoCodeDialog(context),
                    child: Text(
                      'Appliquer un code promo',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
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

  Widget _buildFeatureItem(BuildContext context, {required String title, required String description}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
