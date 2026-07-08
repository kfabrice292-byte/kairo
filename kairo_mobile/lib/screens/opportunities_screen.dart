import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/opportunity_model.dart';
import '../core/providers/opportunity_provider.dart';
import '../widgets/shimmer_loading.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  String _selectedType = 'Tous';

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Type d\'opportunité',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Tous', 'Stage', 'CDI', 'Freelance', 'Bénévolat']
                        .map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() => _selectedType = type);
                                setState(() => _selectedType = type);
                              }
                            },
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Appliquer les filtres',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Opportunités',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.faders()),
              onPressed: _showFilterSheet,
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Toutes les offres'),
              Tab(text: 'Sauvegardées'),
              Tab(text: 'Candidatures'),
            ],
          ),
        ),
        body: Consumer<OpportunityProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.opportunities.isEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (context, index) => const ShimmerProjectCard(),
              );
            }

            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            // Filters
            var allOps = provider.opportunities;
            if (_selectedType != 'Tous') {
              allOps = allOps.where((op) => op.type == _selectedType).toList();
            }

            final savedOps = provider.opportunities
                .where((op) => provider.savedOpportunities.contains(op.id))
                .toList();
            final appliedOps = provider.opportunities.where((op) {
              return currentUserId != null &&
                  op.applicants.contains(currentUserId);
            }).toList();

            return TabBarView(
              children: [
                _buildList(allOps, 'Aucune opportunité disponible'),
                _buildList(
                  savedOps,
                  'Vous n\'avez sauvegardé aucune opportunité.',
                ),
                _buildList(appliedOps, 'Vous n\'avez postulé à aucune offre.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<OpportunityModel> ops, String emptyMessage) {
    if (ops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.briefcase(PhosphorIconsStyle.light),
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
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
  }
}

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel op;

  const _OpportunityCard({required this.op});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final hasApplied =
        currentUserId != null && op.applicants.contains(currentUserId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OpportunityDetailScreen(op: op)),
        );
      },
      child: Card(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.buildings(),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${op.company} • ${op.location}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<OpportunityProvider>(
                    builder: (context, provider, child) {
                      final isSaved = provider.savedOpportunities.contains(
                        op.id,
                      );
                      return IconButton(
                        icon: Icon(
                          isSaved
                              ? PhosphorIcons.bookmarkSimple(
                                  PhosphorIconsStyle.fill,
                                )
                              : PhosphorIcons.bookmarkSimple(),
                          color: isSaved
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                        onPressed: () => provider.toggleSaveOpportunity(op.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                op.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      op.type,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasApplied)
                    Consumer<OpportunityProvider>(
                      builder: (context, provider, child) {
                        final status =
                            provider.applicationStatuses[op.id] ?? 'new';
                        return Row(
                          children: [
                            Icon(
                              PhosphorIcons.checkCircle(
                                PhosphorIconsStyle.fill,
                              ),
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _translateStatus(status),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.clock(),
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Il y a 2j',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'new':
        return 'Envoyée';
      case 'screening':
        return 'En revue';
      case 'interview':
        return 'Entretien programmé';
      case 'offer':
        return 'Offre en cours';
      case 'hired':
        return 'Retenu 🎉';
      case 'rejected':
        return 'Refusée';
      default:
        return 'Envoyée';
    }
  }
}
