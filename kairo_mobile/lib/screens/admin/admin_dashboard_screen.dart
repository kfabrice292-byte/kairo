import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'admin_users_list_screen.dart';
import 'admin_promo_codes_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _premiumUsers = 0;
  int _totalDocsSold = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final totalUsersQuery = await FirebaseFirestore.instance.collection('users').count().get();
      final premiumUsersQuery = await FirebaseFirestore.instance.collection('users').where('isPremium', isEqualTo: true).count().get();
      final docsQuery = await FirebaseFirestore.instance.collection('document_purchases').count().get();

      setState(() {
        _totalUsers = totalUsersQuery.count ?? 0;
        _premiumUsers = premiumUsersQuery.count ?? 0;
        _totalDocsSold = docsQuery.count ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'Administration'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Vue d\'ensemble', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Utilisateurs', _totalUsers.toString(), PhosphorIcons.users(), Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Premium', _premiumUsers.toString(), PhosphorIcons.crown(), Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Docs Vendus', _totalDocsSold.toString(), PhosphorIcons.filePdf(), Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Revenus Estimés', ' F', PhosphorIcons.money(), Colors.purple)),
                  ],
                ),
                const SizedBox(height: 40),
                const Text('Menu Principal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildMenuTile(context, 'Gestion des Utilisateurs', PhosphorIcons.usersThree(), Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersListScreen()));
                }),
                _buildMenuTile(context, 'Codes Promotionnels', PhosphorIcons.tag(), Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPromoCodesScreen()));
                }),
                _buildMenuTile(context, 'Journal d\'Activité', Icons.history, Colors.red, () {}),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
