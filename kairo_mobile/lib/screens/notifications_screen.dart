import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.bellRinging(PhosphorIconsStyle.duotone), size: 64, color: const Color(0xFFF97316)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune notification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vous êtes à jour ! Nous vous préviendrons\ndès qu'il y aura du nouveau.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
