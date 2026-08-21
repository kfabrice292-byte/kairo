import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/models/user_model.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  
  void _showActionDialog(String action) {
    final isGranting = action == 'GRANT_PREMIUM';
    final TextEditingController reasonController = TextEditingController();
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isGranting ? 'Offrir Premium' : 'Retirer Premium'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGranting)
                    DropdownButtonFormField<int>(
                      value: selectedDays,
                      decoration: const InputDecoration(labelText: 'Durée'),
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('7 jours')),
                        DropdownMenuItem(value: 15, child: Text('15 jours')),
                        DropdownMenuItem(value: 30, child: Text('1 mois (30j)')),
                        DropdownMenuItem(value: 90, child: Text('3 mois (90j)')),
                        DropdownMenuItem(value: 180, child: Text('6 mois (180j)')),
                        DropdownMenuItem(value: 365, child: Text('1 an (365j)')),
                        DropdownMenuItem(value: 36500, child: Text('À vie')),
                      ],
                      onChanged: (val) => setState(() => selectedDays = val ?? 30),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motif',
                      hintText: 'Ex: Testeur, Influenceur, Remboursement...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.isEmpty) return;
                    
                    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final batch = FirebaseFirestore.instance.batch();
                    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
                    final adminActionRef = FirebaseFirestore.instance.collection('admin_actions').doc();

                    if (isGranting) {
                      final now = DateTime.now();
                      final until = now.add(Duration(days: selectedDays));
                      batch.update(userRef, {
                        'isPremium': true,
                        'subscriptionStatus': 'PREMIUM_GIFT',
                        'premiumSince': FieldValue.serverTimestamp(),
                        'premiumUntil': Timestamp.fromDate(until),
                      });
                    } else {
                      batch.update(userRef, {
                        'subscriptionStatus': 'FREE',
                      });
                    }

                    batch.set(adminActionRef, {
                      'adminUid': adminUid,
                      'targetUid': widget.user.uid,
                      'action': action,
                      'reason': reasonController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    await batch.commit();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action effectuée avec succès.')),
                      );
                      Navigator.pop(context); // Retour à la liste pour rafraichir
                    }
                  },
                  child: const Text('Confirmer'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'GRANT') _showActionDialog('GRANT_PREMIUM');
              if (value == 'REVOKE') _showActionDialog('REVOKE_PREMIUM');
            },
            itemBuilder: (context) => [
              if (!widget.user.isPremium || widget.user.subscriptionStatus != 'PREMIUM_GIFT')
                const PopupMenuItem(value: 'GRANT', child: Text('Offrir Premium')),
              if (widget.user.isPremium)
                const PopupMenuItem(value: 'REVOKE', child: Text('Retirer Premium', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            const Text('Statistiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStats(),
            const SizedBox(height: 32),
            const Text('Journal d\'activité', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActivityLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: widget.user.photoURL.isNotEmpty ? CachedNetworkImageProvider(widget.user.photoURL) : null,
          child: widget.user.photoURL.isEmpty ? Text(widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32)) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.user.email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.user.isPremium ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.user.subscriptionStatus,
                  style: TextStyle(
                    color: widget.user.isPremium ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Crédits CV', widget.user.cvCredits.toString(), Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activity_logs')
        .where('uid', isEqualTo: widget.user.uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('Aucune activité.');

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final actionType = data['actionType'] ?? 'Inconnu';
            final date = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
            
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(actionType),
              subtitle: Text('// à :'),
            );
          },
        );
      },
    );
  }
}
