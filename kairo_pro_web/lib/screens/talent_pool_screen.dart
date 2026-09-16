import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import 'dashboard_screen.dart';
import 'offers_screen.dart';
import 'login_screen.dart';

class TalentPoolScreen extends StatefulWidget {
  const TalentPoolScreen({super.key});

  @override
  State<TalentPoolScreen> createState() => _TalentPoolScreenState();
}

class _TalentPoolScreenState extends State<TalentPoolScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> allTalents = [];
  List<Map<String, dynamic>> filteredTalents = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchTalents();
  }

  Future<void> _fetchTalents() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'user').get();
      
      if (mounted) {
        setState(() {
          allTalents = usersSnapshot.docs.map((d) {
            final data = d.data();
            data['uid'] = d.id; // Store ID for potential actions
            return data;
          }).toList();
          filteredTalents = List.from(allTalents);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching talents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterTalents(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredTalents = allTalents.where((talent) {
        final name = (talent['name'] ?? '').toString().toLowerCase();
        final title = (talent['professionalTitle'] ?? '').toString().toLowerCase();
        final skills = (talent['skills'] as List<dynamic>? ?? []).join(' ').toLowerCase();
        
        return name.contains(searchQuery) || title.contains(searchQuery) || skills.contains(searchQuery);
      }).toList();
    });
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
            _buildSidebarItem(context, PhosphorIconsBold.users, 'Vivier de Talents', isActive: true),
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
              'Vivier de Talents 👥',
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
          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _filterTalents,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, titre ou compétence...',
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
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.faders),
                label: const Text('Filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  foregroundColor: const Color(0xFF1E293B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: BorderSide(color: Colors.white.withOpacity(0.8))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Talents Grid
          Expanded(
            child: filteredTalents.isEmpty 
              ? const Center(child: Text("Aucun talent ne correspond à votre recherche.", style: TextStyle(color: Color(0xFF64748B))))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredTalents.length,
                  itemBuilder: (context, index) {
                    final talent = filteredTalents[index];
                    return _buildTalentCard(talent);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalentCard(Map<String, dynamic> talent) {
    // Extracting basic info
    final name = talent['name'] ?? 'Anonyme';
    final title = talent['professionalTitle'] ?? 'Étudiant';
    final city = talent['city'] ?? '';
    final country = talent['country'] ?? '';
    final location = (city.isNotEmpty && country.isNotEmpty) ? '$city, $country' : (city.isNotEmpty ? city : country);
    
    // Extracting skills
    List<String> skills = [];
    if (talent['skills'] is List) {
      for (var s in talent['skills']) {
        if (s is Map && s['name'] != null) {
          skills.add(s['name']);
        } else if (s is String) {
          skills.add(s);
        }
      }
    }
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: (talent['photoURL'] != null && talent['photoURL'].toString().isNotEmpty) 
                ? NetworkImage(talent['photoURL']) 
                : null,
            child: (talent['photoURL'] == null || talent['photoURL'].toString().isEmpty) 
                ? const Icon(PhosphorIconsFill.user, color: Color(0xFF94A3B8), size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsRegular.mapPin, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: skills.take(3).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
              )).toList(),
            ),
            if (skills.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+${skills.length - 3} autres', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: const Color(0xFFF97316),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFF97316))
                ),
              ),
              child: const Text('Voir le profil complet'),
            ),
          ),
        ],
      ),
    );
  }
}
