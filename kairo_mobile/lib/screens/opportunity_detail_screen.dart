import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import '../core/models/opportunity_model.dart';
import '../core/providers/opportunity_provider.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final OpportunityModel op;

  const OpportunityDetailScreen({super.key, required this.op});

  @override
  Widget build(BuildContext context) {
    final hasImage = op.imageUrl != null && op.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        actions: [
          Consumer<OpportunityProvider>(
            builder: (context, provider, child) {
              final isSaved = provider.savedOpportunities.contains(op.id);
              return IconButton(
                icon: Icon(
                  isSaved
                      ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill)
                      : PhosphorIcons.bookmarkSimple(),
                  color: isSaved ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            if (hasImage)
              CachedNetworkImage(imageUrl: 
                op.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  PhosphorIcons.briefcase(),
                  size: 64,
                  color: AppColors.primary,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      op.type,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    op.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publié le ${DateFormat('dd MMMM yyyy', 'fr_FR').format(op.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Linkify(
                    onOpen: (link) async {
                      final url = Uri.parse(link.url);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    text: op.description,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    linkStyle: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer<OpportunityProvider>(
            builder: (context, provider, child) {
              final status = provider.applicationStatuses[op.id];
              final hasApplied = status != null;
              final isExternal = op.applicationType == 'external' && op.externalLink != null;

              return ElevatedButton(
                onPressed: hasApplied && !isExternal
                    ? null
                    : () async {
                        if (isExternal) {
                           final url = Uri.parse(op.externalLink!);
                           if (await canLaunchUrl(url)) {
                             await launchUrl(url, mode: LaunchMode.externalApplication);
                           }
                           return;
                        }

                        try {
                          await provider.applyToOpportunity(op.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Candidature envoyée avec succès !'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur réseau. Veuillez réessayer.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: (hasApplied && !isExternal) ? Colors.grey : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExternal 
                          ? 'Postuler sur le site externe' 
                          : (hasApplied ? 'Déjà postulé ($status)' : 'Postuler maintenant'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                    if (isExternal) ...[
                      const SizedBox(width: 8),
                      Icon(PhosphorIcons.arrowSquareOut(), color: Theme.of(context).cardColor, size: 20),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
