import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/providers/opportunity_provider.dart';
import '../core/models/opportunity_model.dart';

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Opportunités', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<OpportunityProvider>(
        builder: (context, provider, child) {
          final ops = provider.opportunities;
          
          if (provider.isLoading && ops.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
          }

          if (ops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.briefcase(PhosphorIconsStyle.light), size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Aucune opportunité disponible', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ops.length,
            itemBuilder: (context, index) {
              return _OpportunityCard(op: ops[index]);
            },
          );
        },
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel op;

  const _OpportunityCard({required this.op});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final hasApplied = currentUserId != null && op.applicants.contains(currentUserId);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIcons.buildings(), color: const Color(0xFFF97316)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(op.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${op.company} • ${op.location}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              op.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(op.type, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                hasApplied
                    ? Row(
                        children: [
                          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          const Text('Candidature envoyée', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : TextButton.icon(
                        onPressed: () async {
                          await context.read<OpportunityProvider>().applyToOpportunity(op.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Candidature envoyée avec votre Profil Kaïro ! 🎉'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: Icon(PhosphorIcons.paperPlaneRight(), size: 18),
                        label: const Text('Postuler (One-Click)'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFF97316),
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


