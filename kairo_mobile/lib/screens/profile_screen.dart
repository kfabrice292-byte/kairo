import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/providers/auth_provider.dart';
import '../widgets/kairo_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchCVBuilder() async {
    final Uri url = Uri.parse('https://kairo-app.web.app/builder.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userData = auth.userData;
    
    if (userData == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
    }

    final name = userData['name'] ?? 'Utilisateur';
    final email = userData['email'] ?? auth.currentUser?.email ?? '';
    final photoURL = userData['photoURL'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=F97316&color=fff';
    
    final university = userData['university'] as String? ?? '';
    final fieldOfStudy = userData['fieldOfStudy'] as String? ?? '';
    final level = userData['level'] as String? ?? '';
    final country = userData['country'] as String? ?? '';
    final skills = List<String>.from(userData['skills'] ?? []);
    final interests = List<String>.from(userData['interests'] ?? []);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.signOut()),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Arrière-plan animé / complexe
                    Container(
                      height: 340,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF97316).withOpacity(0.5),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -20,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    // Contenu principal
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => _EditProfileDialog(userData: userData),
                              );
                            },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundImage: NetworkImage(photoURL),
                            backgroundColor: Colors.grey.shade800,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1E293B), width: 3),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fieldOfStudy.isEmpty 
                      ? 'Complétez votre profil' 
                      : '$fieldOfStudy${level.isNotEmpty ? " • $level" : ""}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                      fontStyle: fieldOfStudy.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (university.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.bank(PhosphorIconsStyle.fill), size: 14, color: Colors.grey.shade300),
                              const SizedBox(width: 6),
                              Text(university, style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
                            ],
                          ),
                        ),
                      if (country.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill), size: 14, color: Colors.grey.shade300),
                              const SizedBox(width: 6),
                              Text(country, style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _EditProfileDialog(userData: userData),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Éditer mon profil', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (skills.isNotEmpty)
              _ProfileSection(
                title: 'Compétences',
                icon: PhosphorIcons.lightning(),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => _Badge(text: s, isSkill: true)).toList(),
                ),
              )
            else
              _ProfileSection(
                title: 'Compétences',
                icon: PhosphorIcons.lightning(),
                child: Text('Aucune compétence ajoutée. Éditez votre profil pour en rajouter.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              ),

            if (interests.isNotEmpty)
              _ProfileSection(
                title: 'Centres d\'intérêt',
                icon: PhosphorIcons.heart(),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map((i) => _Badge(text: i, isSkill: false)).toList(),
                ),
              )
            else
              _ProfileSection(
                title: 'Centres d\'intérêt',
                icon: PhosphorIcons.heart(),
                child: Text('Aucun centre d\'intérêt ajouté.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
              ),

            const SizedBox(height: 12),

            // Kaïro Studio CV Builder Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(PhosphorIcons.magicWand(), color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Kaïro Studio',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crée ton CV premium généré par IA et décroche ton prochain stage !',
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _launchCVBuilder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Créer mon CV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isSkill;

  const _Badge({required this.text, required this.isSkill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSkill ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSkill ? Colors.orange.shade100 : Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSkill ? Colors.orange.shade800 : Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  const _EditProfileDialog({required this.userData});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _fieldController;
  late TextEditingController _universityController;
  late TextEditingController _countryController;
  late TextEditingController _skillsController;
  late TextEditingController _interestsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _fieldController = TextEditingController(text: widget.userData['fieldOfStudy']);
    _universityController = TextEditingController(text: widget.userData['university']);
    _countryController = TextEditingController(text: widget.userData['country']);
    
    final skills = widget.userData['skills'] as List<dynamic>?;
    _skillsController = TextEditingController(text: skills?.join(', '));
    
    final interests = widget.userData['interests'] as List<dynamic>?;
    _interestsController = TextEditingController(text: interests?.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldController.dispose();
    _universityController.dispose();
    _countryController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  File? _newImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newImage = File(image.path);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    String? photoUrl;
    if (_newImage != null) {
      try {
        final bytes = await _newImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': '42583eab8962481f83526a0882f3d384',
            'image': base64Image,
          },
        );
        
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          photoUrl = jsonResponse['data']['display_url'];
        } else {
          debugPrint('ImgBB API Error: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error uploading image to ImgBB: $e');
      }
    }

    final updateData = {
      'name': _nameController.text,
      'fieldOfStudy': _fieldController.text,
      'university': _universityController.text.trim(),
      'country': _countryController.text.trim(),
      'skills': _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'interests': _interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };

    if (photoUrl != null) {
      updateData['photoURL'] = photoUrl;
    }

    try {
      await context.read<AuthProvider>().updateProfile(updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Éditer mon profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _newImage != null 
                            ? FileImage(_newImage!) as ImageProvider
                            : (widget.userData['photoURL'] != null ? NetworkImage(widget.userData['photoURL']) : null),
                        child: _newImage == null && widget.userData['photoURL'] == null
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF97316),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              KairoTextField(
                controller: _nameController,
                hintText: 'Nom Complet',
                prefixIcon: PhosphorIcons.user(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _fieldController,
                hintText: 'Filière d\'études',
                prefixIcon: PhosphorIcons.student(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _universityController,
                hintText: 'Université / École',
                prefixIcon: PhosphorIcons.bank(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _countryController,
                hintText: 'Pays de résidence',
                prefixIcon: PhosphorIcons.mapPin(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _skillsController,
                hintText: 'Compétences (séparées par une virgule)',
                prefixIcon: PhosphorIcons.lightning(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _interestsController,
                hintText: 'Centres d\'intérêt (séparés par une virgule)',
                prefixIcon: PhosphorIcons.heart(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sauvegarder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
