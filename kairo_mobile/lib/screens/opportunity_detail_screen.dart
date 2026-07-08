import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/opportunity_model.dart';
import '../core/providers/opportunity_provider.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/providers/auth_provider.dart' as app_auth;
import 'profile/cv_edit_screen.dart';
import 'profile/cover_letter_screen.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final OpportunityModel op;

  const OpportunityDetailScreen({super.key, required this.op});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Consumer<OpportunityProvider>(
            builder: (context, provider, child) {
              final isSaved = provider.savedOpportunities.contains(op.id);
              return IconButton(
                icon: Icon(
                  isSaved
                      ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                      : PhosphorIcons.bookmarkSimple(),
                  color: isSaved ? AppColors.primary : Colors.black87,
                ),
                onPressed: () => provider.toggleSaveOpportunity(op.id),
              );
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.shareNetwork()),
            onPressed: () {
              // Share logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Logo & Title
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    PhosphorIcons.buildings(),
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        op.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        op.company,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBadge(PhosphorIcons.mapPin(), op.location),
                _buildInfoBadge(PhosphorIcons.briefcase(), op.type),
                _buildInfoBadge(
                  PhosphorIcons.clock(),
                  DateFormat('dd MMM').format(op.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'Description de l\'offre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              op.description,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Compatibility Score
            Consumer<OpportunityProvider>(
              builder: (context, provider, child) {
                final score = provider.matchScores[op.id] ?? 0;
                Color scoreColor = score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scoreColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Votre compatibilité',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              score >= 80
                                  ? 'Excellent profil pour ce poste !'
                                  : score >= 50
                                      ? 'Profil intéressant, quelques compétences manquantes.'
                                      : 'Ce poste demande des compétences que vous n\'avez pas encore listées.',
                              style: TextStyle(
                                fontSize: 14,
                                color: scoreColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Skills
            if (op.mandatorySkills.isNotEmpty) ...[
              const Text(
                'Compétences requises',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: op.mandatorySkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Company info (Mock)
            const Text(
              'À propos de l\'entreprise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${op.company} est une entreprise leader dans son domaine, offrant un environnement de travail dynamique et innovant.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Consumer<OpportunityProvider>(
          builder: (context, provider, child) {
            final hasApplied =
                currentUserId != null && op.applicants.contains(currentUserId);
            final status = provider.applicationStatuses[op.id];

            if (hasApplied || status != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Candidature envoyée (${_translateStatus(status ?? "new")})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ElevatedButton(
              onPressed: () => _showApplicationDialog(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Postuler en 1-clic',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showApplicationDialog(BuildContext context, OpportunityProvider provider) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Check profile completion
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};
    
    List<String> missingFields = [];
    if ((userData['phone'] ?? '').isEmpty) missingFields.add('Numéro de téléphone');
    if ((userData['university'] ?? '').isEmpty) missingFields.add('Université');
    if ((userData['jobTitle'] ?? '').isEmpty) missingFields.add('Titre professionnel');
    if ((userData['bio'] ?? '').isEmpty) missingFields.add('Biographie');

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                missingFields.isNotEmpty ? 'Votre candidature est presque prête' : 'Récapitulatif de candidature',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (missingFields.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations à compléter dans votre profil pour postuler :',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      ...missingFields.map((f) => Text('• $f', style: const TextStyle(color: Colors.orange))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mettre à jour mon profil Kaïro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                if (op.requiredDocuments.isNotEmpty) ...[
                  const Text('Documents requis par le recruteur :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...op.requiredDocuments.map((docItem) {
                    final isCV = docItem.toLowerCase().contains('cv') || docItem.toLowerCase().contains('curriculum');
                    final isLetter = docItem.toLowerCase().contains('lettre') || docItem.toLowerCase().contains('motivation') || docItem.toLowerCase().contains('cover');
                    
                    return Row(
                      children: [
                        Icon(PhosphorIcons.filePdf(), color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(docItem),
                        const Spacer(),
                        if (isCV)
                          TextButton(
                            onPressed: () {
                              final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
                              if (authProvider.userModel == null) return;
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CVEditScreen(user: authProvider.userModel!)),
                              );
                            },
                            child: const Text('Générer Kaïro CV', style: TextStyle(color: AppColors.primary)),
                          )
                        else if (isLetter)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CoverLetterScreen()),
                              );
                            },
                            child: const Text('Générer avec l\'IA', style: TextStyle(color: AppColors.primary)),
                          )
                        else
                          TextButton(
                            onPressed: () {},
                            child: const Text('Téléverser', style: TextStyle(color: AppColors.primary)),
                          ),
                      ],
                    );
                  }),
                  const Divider(height: 32),
                ],
                const Text('Votre candidature comprend :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildCheckItem('Profil Kaïro vérifié'),
                _buildCheckItem('CV généré automatiquement'),
                _buildCheckItem('Projets et Expériences'),
                _buildCheckItem('Compétences validées'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await provider.applyToOpportunity(op.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Votre candidature a été envoyée avec succès ! 🎉'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirmer ma candidature', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'new':
        return 'Reçue';
      case 'screening':
        return 'En revue';
      case 'interview':
        return 'Entretien programmé';
      case 'offer':
        return 'Offre en cours';
      case 'hired':
        return 'Retenue 🎉';
      case 'rejected':
        return 'Refusée';
      default:
        return 'Envoyée';
    }
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
