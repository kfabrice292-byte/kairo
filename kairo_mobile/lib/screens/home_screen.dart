import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/opportunity_provider.dart';
import '../core/models/user_model.dart';
import '../core/models/opportunity_model.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

// Screens imports for navigation
import 'profile/cv_edit_screen.dart';
import 'profile/cover_letter_screen.dart';
import 'search_screen.dart';
import 'profile/portfolio_edit_screen.dart';
import 'profile_screen.dart';
import 'opportunities_screen.dart';
import 'opportunity_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabTapped;

  const HomeScreen({super.key, this.onTabTapped});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch opportunities when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OpportunityProvider>().loadOpportunities(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Opacity(
                opacity: 0,
                child: _buildHeader(context, user, size),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // 2. Quick Actions Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickAction(
                              context,
                              title: 'Mon CV',
                              icon: PhosphorIcons.fileText(),
                              color: Colors.blue,
                              onTap: () {
                                context.push('/cv-edit');
                              },
                            ),
                            _buildQuickAction(
                              context,
                              title: 'Rechercher',
                              icon: PhosphorIcons.magnifyingGlass(),
                              color: AppColors.primary,
                              onTap: () {
                                context.push('/search');
                              },
                            ),
                            _buildQuickAction(
                              context,
                              title: 'Lettre',
                              icon: PhosphorIcons.envelopeOpen(),
                              color: Colors.green,
                              onTap: () {
                                context.push('/cover-letter');
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

            // 3. Recommended Opportunities (Dynamic Horizontal List)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommandé pour vous',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.onTabTapped != null) {
                        widget.onTabTapped!(1); // Index 1 is Opportunities
                      }
                    },
                    child: Text(
                      'Voir tout',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            _buildOpportunitiesList(context),

            const SizedBox(height: 32),

            // 4. Interactive CTA Banner for Profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildProfileCTA(context, user),
            ),
            
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(context, user, size),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.name.isNotEmpty ? user.name : 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  user.professionalTitle.isNotEmpty 
                      ? user.professionalTitle 
                      : 'Complétez votre profil pour plus de matchs.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: user.photoURL.isNotEmpty ? NetworkImage(user.photoURL) : null,
              child: user.photoURL.isEmpty 
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesList(BuildContext context) {
    return Consumer<OpportunityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.opportunities.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (provider.opportunities.isEmpty) {
          return Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Center(
              child: Text(
                'Aucune opportunité pour le moment.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Take top 5 for home screen
        final topOpps = provider.opportunities.take(5).toList();

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topOpps.length,
            itemBuilder: (context, index) {
              final opp = topOpps[index];
              return _buildOpportunityCard(context, opp);
            },
          ),
        );
      },
    );
  }

  Widget _buildOpportunityCard(BuildContext context, OpportunityModel opp) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OpportunityDetailScreen(op: opp)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(PhosphorIcons.briefcase(), color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opp.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            opp.company,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(), size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        (opp.location.isEmpty || opp.location.contains('Non spécifié')) 
                            ? (opp.remoteWork == 'Oui' ? 'Télétravail' : 'Lieu non précisé') 
                            : opp.location,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        opp.type,
                        style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'Voir les détails',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCTA(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complétez votre profil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Augmentez vos chances d\'être repéré par les recruteurs de 3x.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.onTabTapped != null) {
                      widget.onTabTapped!(3); // Index 3 is Profile
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
            color: AppColors.primary,
            size: 64,
          ),
        ],
      ),
    );
  }
}

