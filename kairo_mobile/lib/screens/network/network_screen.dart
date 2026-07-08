import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/network_provider.dart';
import '../../widgets/connection_card.dart';
import '../../widgets/shimmer_loading.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Réseau',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Reçues'),
            Tab(text: 'Envoyées'),
            Tab(text: 'Connexions'),
          ],
        ),
      ),
      body: Consumer<NetworkProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.connections.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerConnectionCard(),
            );
          }

          // We use FirebaseAuth in the child methods where needed.

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReceivedRequests(provider),
              _buildSentRequests(provider),
              _buildConnections(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReceivedRequests(NetworkProvider provider) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final reqs = provider.connections
        .where((c) => c.receiverId == currentUserId && c.status == 'pending')
        .toList();

    if (reqs.isEmpty)
      return const Center(child: Text('Aucune invitation reçue.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (context, index) {
        final user = provider.usersCache[reqs[index].senderId];
        if (user == null) return const SizedBox.shrink();
        return ConnectionCard(user: user);
      },
    );
  }

  Widget _buildSentRequests(NetworkProvider provider) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final reqs = provider.connections
        .where((c) => c.senderId == currentUserId && c.status == 'pending')
        .toList();

    if (reqs.isEmpty)
      return const Center(child: Text('Aucune invitation envoyée.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (context, index) {
        final user = provider.usersCache[reqs[index].receiverId];
        if (user == null) return const SizedBox.shrink();
        return ConnectionCard(user: user);
      },
    );
  }

  Widget _buildConnections(NetworkProvider provider) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final conns = provider.connections
        .where((c) => c.status == 'accepted')
        .toList();

    if (conns.isEmpty) return const Center(child: Text('Aucune connexion.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conns.length,
      itemBuilder: (context, index) {
        final c = conns[index];
        final otherId = c.senderId == currentUserId ? c.receiverId : c.senderId;
        final user = provider.usersCache[otherId];
        if (user == null) return const SizedBox.shrink();
        return ConnectionCard(user: user);
      },
    );
  }
}
