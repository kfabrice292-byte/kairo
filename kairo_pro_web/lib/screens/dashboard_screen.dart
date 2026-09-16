import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import 'talent_pool_screen.dart';
import 'offers_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalCandidates = 0;
  int activeOffers = 0;
  int upcomingInterviews = 0;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> recentCandidates = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Fetch users with role 'user'
      final usersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'user').limit(50).get();
      
      if (mounted) {
        setState(() {
          totalCandidates = usersSnapshot.docs.length;
          recentCandidates = usersSnapshot.docs.map((d) => d.data()).toList();
          
          // Mocked stats for others
          activeOffers = 3;
          upcomingInterviews = 12;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFFDBA74).withValues(alpha: 0.4), // orange-300
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFE9D5FF).withValues(alpha: 0.4), // purple-200
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Layout
          Row(
            children: [
              // Sidebar
              _buildSidebar(context),
              
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    _buildTopbar(),
                    Expanded(
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
                          : _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.all(16.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(PhosphorIconsBold.briefcase, color: Color(0xFFF97316), size: 28),
                const SizedBox(width: 12),
                Text(
                  'Kaïro Pro',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildSidebarItem(context, PhosphorIconsBold.squaresFour, 'Tableau de bord', isActive: true),
            const SizedBox(height: 8),
            _buildSidebarItem(context, PhosphorIconsRegular.users, 'Vivier de Talents', onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TalentPoolScreen()));
            }),
            const SizedBox(height: 8),
            _buildSidebarItem(context, PhosphorIconsRegular.target, 'Mes Offres', onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OffersScreen()));
            }),
            const Spacer(),
            _buildSidebarItem(context, PhosphorIconsRegular.gear, 'Paramètres'),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF97316).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? const Color(0xFFF97316) : const Color(0xFF64748B)),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFF97316) : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildTopbar() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        borderRadius: BorderRadius.circular(50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bonjour, ${user?.displayName ?? 'Recruteur'} 👋',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.bell, color: Color(0xFF64748B)),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _logout,
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFF97316),
                        child: Icon(PhosphorIconsFill.user, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('Candidats Inscrits', totalCandidates.toString(), PhosphorIconsFill.users)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Entretiens Prévus', upcomingInterviews.toString(), PhosphorIconsFill.calendarBlank, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Offres Actives', activeOffers.toString(), PhosphorIconsFill.target, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Table
          Text(
            'Talents Récents',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentCandidates.isEmpty ? 1 : recentCandidates.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                if (recentCandidates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('Aucun talent trouvé.')),
                  );
                }
                
                final candidate = recentCandidates[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: (candidate['photoURL'] != null && candidate['photoURL'].toString().isNotEmpty) 
                        ? NetworkImage(candidate['photoURL']) 
                        : null,
                    child: (candidate['photoURL'] == null || candidate['photoURL'].toString().isEmpty) 
                        ? const Icon(PhosphorIconsFill.user, color: Color(0xFF94A3B8))
                        : null,
                  ),
                  title: Text(candidate['name'] ?? 'Anonyme', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(candidate['professionalTitle'] ?? 'Étudiant'),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFC),
                      foregroundColor: const Color(0xFFF97316),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: const BorderSide(color: Color(0xFFF97316))),
                    ),
                    child: const Text('Voir le profil'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = const Color(0xFFF97316)}) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
