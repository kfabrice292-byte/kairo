import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../core/models/opportunity_model.dart';
import '../core/providers/opportunity_provider.dart';
import '../core/providers/auth_provider.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'premium/premium_subscription_screen.dart';
import 'opportunity_detail_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state_widget.dart';

class OpportunitiesScreen extends StatefulWidget { const OpportunitiesScreen({super.key}); @override State<OpportunitiesScreen> createState() => _OpportunitiesScreenState(); } class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Opportunités',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Pour vous'),
              Tab(text: 'Sauvegardées'),
            ],
          ),
        ),
        body: Consumer2<OpportunityProvider, AuthProvider>(
          builder: (context, provider, authProvider, child) {
            if (provider.isLoading && provider.opportunities.isEmpty) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (context, index) => const ShimmerProjectCard(),
              );
            }

            final allOps = provider.opportunities;

            final savedOps = provider.opportunities
                .where((op) => provider.savedOpportunities.contains(op.id))
                .toList();

            return TabBarView(
              children: [
                _buildList(context, allOps, 'Aucune opportunité disponible'),
                _buildList(context, savedOps, 'Vous n\'avez sauvegardé aucune opportunité.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<OpportunityModel> ops, String emptyMessage) {
    if (ops.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucune opportunité',
        message: emptyMessage,
        icon: PhosphorIconsLight.briefcase,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OpportunityProvider>().loadOpportunities(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            context.read<OpportunityProvider>().loadMoreOpportunities();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ops.length + (context.watch<OpportunityProvider>().hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == ops.length) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: ShimmerProjectCard(),
              );
            }
            return _OpportunityCard(op: ops[index]);
          },
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final OpportunityModel op;

  const _OpportunityCard({required this.op});

  @override
  Widget build(BuildContext context) {
    final hasImage = op.imageUrl != null && op.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OpportunityDetailScreen(op: op)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: op.imageUrl!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  PhosphorIcons.briefcase(),
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                op.type,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          op.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          op.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Consumer<OpportunityProvider>(
                    builder: (context, provider, child) {
                      final isSaved = provider.savedOpportunities.contains(op.id);
                      return IconButton(
                        icon: Icon(
                          isSaved
                              ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                              : PhosphorIcons.bookmarkSimple(),
                          color: isSaved ? AppColors.primary : Colors.grey.shade400,
                        ),
                        onPressed: () => provider.toggleSaveOpportunity(op.id),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
