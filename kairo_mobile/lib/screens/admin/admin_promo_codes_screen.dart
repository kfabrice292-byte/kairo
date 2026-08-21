import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math';

class AdminPromoCodesScreen extends StatefulWidget {
  const AdminPromoCodesScreen({super.key});

  @override
  State<AdminPromoCodesScreen> createState() => _AdminPromoCodesScreenState();
}

class _AdminPromoCodesScreenState extends State<AdminPromoCodesScreen> {
  
  void _showCreateDialog() {
    final codeController = TextEditingController();
    final maxUsesController = TextEditingController(text: '1');
    final durationController = TextEditingController(text: '30');
    String selectedType = 'SINGLE';

    codeController.text = 'KAIROVIP' + (Random().nextInt(900) + 100).toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouveau Code Promo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Code'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'SINGLE', child: Text('Usage unique (1 fois)')),
                      DropdownMenuItem(value: 'MULTI', child: Text('Multi-usage (limité)')),
                      DropdownMenuItem(value: 'UNLIMITED', child: Text('Illimité')),
                    ],
                    onChanged: (val) => setState(() => selectedType = val ?? 'SINGLE'),
                  ),
                  const SizedBox(height: 16),
                  if (selectedType != 'UNLIMITED')
                    TextField(
                      controller: maxUsesController,
                      decoration: const InputDecoration(labelText: 'Nombre d\'utilisations max'),
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Durée Premium (jours)'),
                    keyboardType: TextInputType.number,
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
                    if (codeController.text.isEmpty) return;
                    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    
                    await FirebaseFirestore.instance.collection('promo_codes').doc().set({
                      'code': codeController.text.toUpperCase(),
                      'durationDays': int.tryParse(durationController.text) ?? 30,
                      'maxUses': selectedType == 'UNLIMITED' ? 0 : (int.tryParse(maxUsesController.text) ?? 1),
                      'currentUses': 0,
                      'type': selectedType,
                      'createdBy': adminUid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code promo créé !')));
                    }
                  },
                  child: const Text('Créer'),
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
        title: const Text('Codes Promotionnels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promo_codes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Aucun code promo créé.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final code = data['code'] ?? '';
              final durationDays = data['durationDays'] ?? 0;
              final currentUses = data['currentUses'] ?? 0;
              final maxUses = data['maxUses'] ?? 0;
              final type = data['type'] ?? 'SINGLE';
              final isUnlimited = type == 'UNLIMITED';
              final isExhausted = !isUnlimited && currentUses >= maxUses;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    isExhausted ? Icons.not_interested : Icons.local_offer,
                    color: isExhausted ? Colors.grey : Colors.orange,
                  ),
                  title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                  subtitle: Text('Durée:  jours | Utilisations: '),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('promo_codes').doc(docs[index].id).delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
