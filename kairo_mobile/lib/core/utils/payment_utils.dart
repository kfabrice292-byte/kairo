import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';
import '../../screens/premium/premium_subscription_screen.dart';
import '../../widgets/ashtech_payment_dialog.dart';
import '../theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PaymentUtils {
  static Future<void> checkAndConsumeCredit(
    BuildContext context, {
    required VoidCallback onGranted,
    required String documentName,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) return;

    if (user.isPremium) {
      onGranted();
      return;
    }

    if (user.cvCredits > 0) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'cvCredits': FieldValue.increment(-1),
      });
      authProvider.updateProfile({'cvCredits': user.cvCredits - 1});
      onGranted();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => _PaymentBottomSheet(
        documentName: documentName,
        onGranted: () {
          Navigator.pop(bottomSheetContext); // Close the bottom sheet
          
          final latestUser = context.read<AuthProvider>().userModel;
          if (latestUser != null && !latestUser.isPremium && latestUser.cvCredits > 0) {
            FirebaseFirestore.instance.collection('users').doc(latestUser.uid).update({
              'cvCredits': FieldValue.increment(-1),
            });
            context.read<AuthProvider>().updateProfile({'cvCredits': latestUser.cvCredits - 1});
          }
          
          onGranted();
        },
      ),
    );
  }

  static Future<void> _processPayment(BuildContext context, user, String type) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AshtechPaymentDialog(
        user: user,
        paymentType: type,
        onSuccess: () {
          // Success is mostly handled by webhook + Firestore snapshot listener
          // But we can show a quick message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement initié. Votre contenu sera débloqué automatiquement.'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

class _PaymentBottomSheet extends StatefulWidget {
  final VoidCallback onGranted;
  final String documentName;
  
  const _PaymentBottomSheet({required this.onGranted, required this.documentName});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  bool _granted = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    // Check if user just got premium or credits
    if (user != null && (user.isPremium || user.cvCredits > 0) && !_granted) {
      _granted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onGranted();
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorIcons.lockKey(PhosphorIconsStyle.fill), size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Accès Réservé',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (_granted) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text('Paiement validé ! Génération en cours...', textAlign: TextAlign.center),
            ] else ...[
              Text(
                'Générez ce document avec un paiement unique, ou passez à Kaïro Pro pour tout débloquer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumSubscriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Passer à Kaïro Pro (1000 FCFA/mois)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton(
                onPressed: () {
                  PaymentUtils._processPayment(context, user, 'cv');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Acheter 1 accès unique (350 FCFA)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
