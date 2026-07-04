import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile/public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un membre...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur disponible."));
                }

                // Filter out current user
                final users = snapshot.data!.docs.where((doc) => doc.id != _currentUserId).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Aucun autre membre disponible."));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Text('Membres suggérés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final data = users[index].data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Utilisateur';
                          final photoURL = data['photoURL'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}';
                          final fieldOfStudy = data['fieldOfStudy'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(photoURL),
                              backgroundColor: Colors.grey.shade200,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: fieldOfStudy.isNotEmpty ? Text(fieldOfStudy) : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.person_outline, color: Color(0xFFF97316)),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(userId: users[index].id),
                                ));
                              },
                            ),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(userId: users[index].id),
                              ));
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur trouvé."));
                }

                // Filter out current user
                final users = snapshot.data!.docs.where((doc) => doc.id != _currentUserId).toList();

                if (users.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur trouvé."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Utilisateur';
                    final photoURL = data['photoURL'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}';
                    final fieldOfStudy = data['fieldOfStudy'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(photoURL),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: fieldOfStudy.isNotEmpty ? Text(fieldOfStudy) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.person_outline, color: Color(0xFFF97316)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(userId: users[index].id),
                          ));
                        },
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: users[index].id),
                        ));
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
