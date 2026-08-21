import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../screens/premium/premium_subscription_screen.dart';

class SubscriptionReminderBanner extends StatelessWidget {
  const SubscriptionReminderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) return const SizedBox.shrink();

    if (user.premiumUntil == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final expirationDate = user.premiumUntil!;
    final difference = expirationDate.difference(now);
    final daysRemaining = difference.inDays;

    bool shouldShow = false;
    String message = '';

    if (daysRemaining == 5 || daysRemaining == 3 || daysRemaining == 2) {
      shouldShow = true;
      message = 'Votre abonnement Kaïro Pro se termine dans $daysRemaining jours. N\'attendez pas la coupure !';
    } else if (daysRemaining == 1 || (daysRemaining == 0 && difference.inHours > 0)) {
      shouldShow = true;
      message = 'Votre abonnement Kaïro Pro se termine demain. Renouvelez-le !';
    } else if (daysRemaining <= 0 && daysRemaining >= -3) {
      shouldShow = true;
      message = 'Votre abonnement Kaïro Pro est terminé. Renouvelez pour conserver vos avantages.';
    }

    if (!shouldShow) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Renouveler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
