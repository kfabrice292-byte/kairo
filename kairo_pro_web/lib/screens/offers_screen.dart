import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import 'dashboard_screen.dart';
import 'talent_pool_screen.dart';
import 'login_screen.dart';
import 'create_offer_dialog.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> offers = [];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Fetch from 'jobs' or 'job_offers'
      final snapshot = await firestore.collection('opportunities').orderBy('createdAt', descending: true).get();
      
      if (mounted) {
        setState(() {
          offers = snapshot.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
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

  void _showCreateOfferDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CreateOfferDialog(
          onOfferCreated: () {
            // Refresh list
            _fetchOffers();
          },
        );
      },
    );
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
                color: const Color(0xFFFDBA74).withOpacity(0.4),
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
                color: const Color(0xFFE9D5FF).withOpacity(0.4),
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
            _buildSidebarItem(context, PhosphorIconsRegular.squaresFour, 'Tableau de bord', onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }),
            const SizedBox(height: 8),
            _buildSidebarItem(context, PhosphorIconsRegular.users, 'Vivier de Talents', onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const TalentPoolScreen()));
            }),
            const SizedBox(height: 8),
            _buildSidebarItem(context, PhosphorIconsBold.target, 'Mes Offres', isActive: true),
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
        color: isActive ? const Color(0xFFF97316).withOpacity(0.1) : Colors.transparent,
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
        onTap: onTap,
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
              'Mes Offres d\'Emploi 💼',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une offre...',
                    prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color(0xFFF97316)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showCreateOfferDialog,
                icon: const Icon(PhosphorIconsBold.plus),
                label: const Text('Nouvelle Offre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Offers List
          Expanded(
            child: offers.isEmpty 
              ? const Center(child: Text("Vous n'avez pas encore publié d'offre.", style: TextStyle(color: Color(0xFF64748B))))
              : ListView.separated(
                  itemCount: offers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return _buildOfferCard(offer);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final title = offer['title'] ?? 'Offre sans titre';
    final type = offer['type'] ?? 'CDI';
    final location = offer['location'] ?? 'Non spécifié';
    final status = offer['status'] ?? 'Active';
    final applications = offer['applicationsCount'] ?? 0;
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(PhosphorIconsRegular.briefcase, color: Color(0xFFF97316), size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(type, PhosphorIconsRegular.clock),
                    const SizedBox(width: 12),
                    _buildBadge(location, PhosphorIconsRegular.mapPin),
                    const SizedBox(width: 12),
                    _buildBadge(status, PhosphorIconsRegular.circleHalf, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$applications',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFF97316)),
              ),
              const Text(
                'Candidatures',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 32),
          IconButton(
            onPressed: () {},
            icon: const Icon(PhosphorIconsRegular.pencilSimple, color: Color(0xFF64748B)),
            tooltip: 'Modifier',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(PhosphorIconsRegular.trash, color: Colors.red),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, {Color color = const Color(0xFF64748B)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
