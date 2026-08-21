import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../../widgets/connection_card.dart';
import '../../core/models/user_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCountry = '';
  String _selectedDomain = '';
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un membre...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          autofocus: true,
          style: TextStyle(fontSize: 16),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          IconButton(
            icon: Icon(
              PhosphorIcons.faders(),
              color: (_selectedCountry.isNotEmpty || _selectedDomain.isNotEmpty)
                  ? AppColors.primary
                  : Colors.grey.shade700,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_selectedCountry.isNotEmpty) {
      query = query.where('country', isEqualTo: _selectedCountry);
    }
    if (_selectedDomain.isNotEmpty) {
      query = query.where('fieldOfStudy', isEqualTo: _selectedDomain);
    }

    // Name search requires it to be the first order by in some configurations
    // or just local filtering if simple. We will do local filtering for text search if there are other filters.
    // But for a simple implementation:
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(30).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun utilisateur trouvé."));
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((u) => u.uid != _currentUserId)
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text("Aucun utilisateur trouvé avec ces critères."),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return ConnectionCard(user: users[index]);
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String tempCountry = _selectedCountry;
        String tempDomain = _selectedDomain;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCountry = '';
                            tempDomain = '';
                          });
                        },
                        child: Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Pays',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCountry.isEmpty ? null : tempCountry,
                    hint: Text('Tous les pays'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    items:
                        [
                              'Sénégal',
                              'Côte d\'Ivoire',
                              'France',
                              'Maroc',
                              'Cameroun',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (val) =>
                        setModalState(() => tempCountry = val ?? ''),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Domaine d\'études',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempDomain.isEmpty ? null : tempDomain,
                    hint: Text('Tous les domaines'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    items:
                        [
                              'Informatique',
                              'Business',
                              'Design',
                              'Marketing',
                              'Ingénierie',
                            ]
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged: (val) =>
                        setModalState(() => tempDomain = val ?? ''),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCountry = tempCountry;
                        _selectedDomain = tempDomain;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).iconTheme.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Appliquer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
