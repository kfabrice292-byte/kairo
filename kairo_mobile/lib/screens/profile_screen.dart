import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../core/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/utils/portfolio_generator.dart';
import 'profile/cv_edit_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/kairo_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
    }

    final name = user.name.isNotEmpty ? user.name : 'Utilisateur';
    final photoURL = user.photoURL.isNotEmpty ? user.photoURL : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=F97316&color=fff';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.gear()),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Banner (Couverture)
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: user.coverPhoto.isEmpty ? const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ) : null,
                      image: user.coverPhoto.isNotEmpty ? DecorationImage(
                        image: NetworkImage(user.coverPhoto),
                        fit: BoxFit.cover,
                      ) : null,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  // Contenu principal (Avatar + Infos)
                  Padding(
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => _EditProfileDialog(user: user),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundImage: NetworkImage(photoURL),
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF97316),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (user.professionalTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user.professionalTitle,
                              style: const TextStyle(fontSize: 16, color: Color(0xFFF97316), fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          user.fieldOfStudy.isEmpty 
                            ? 'Complétez votre profil' 
                            : '${user.fieldOfStudy}${user.studyLevel.isNotEmpty ? ' • ${user.studyLevel}' : ''}',
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.city.isEmpty && user.country.isEmpty
                              ? 'Localisation non renseignée'
                              : '${user.city}, ${user.country}',
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => CVEditScreen(user: user)));
                                },
                                icon: Icon(PhosphorIcons.fileText(), size: 18),
                                label: const Text('Générer CV'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.textTheme.bodyLarge?.color,
                                  side: BorderSide(color: theme.dividerColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  PortfolioGenerator.generatePortfolio(user);
                                },
                                icon: Icon(PhosphorIcons.briefcase(), size: 18),
                                label: const Text('Portfolio'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.textTheme.bodyLarge?.color,
                                  side: BorderSide(color: theme.dividerColor),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        if (user.bio.isNotEmpty)
                          _buildSection('À propos', [
                            Text(user.bio, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.5, fontSize: 15)),
                          ], theme),
                          
                        if (user.skills.isNotEmpty)
                          _buildSection('Compétences', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.skills.map((skill) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF97316).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.2)),
                                ),
                                child: Text(skill, style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 13)),
                              )).toList(),
                            )
                          ], theme),

                        if (user.experiences.isNotEmpty)
                          _buildSection('Expériences', user.experiences.map((exp) => _buildExperienceCard(exp, theme)).toList(), theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSection(String title, List<Widget> children, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Experience exp, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exp.title, 
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                exp.period, 
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(exp.organization, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 14)),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp.description, 
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7), height: 1.4, fontSize: 13),
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const _EditProfileDialog({required this.user});

@override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _fieldController = TextEditingController();
  final _levelController = TextEditingController();
  final _universityController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _skillsController = TextEditingController();
  
  File? _newImage;
  File? _newCoverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _titleController.text = widget.user.professionalTitle;
    _bioController.text = widget.user.bio;
    _fieldController.text = widget.user.fieldOfStudy;
    _levelController.text = widget.user.studyLevel;
    _universityController.text = widget.user.university;
    _countryController.text = widget.user.country;
    _cityController.text = widget.user.city;
    _skillsController.text = widget.user.skills.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _fieldController.dispose();
    _levelController.dispose();
    _universityController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isCover = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isCover) {
          _newCoverImage = File(pickedFile.path);
        } else {
          _newImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    String? photoUrl;
    String? coverUrl;
    
    Future<String?> uploadToImgBB(File imageFile) async {
      try {
        final bytes = await imageFile.readAsBytes();
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
          return jsonResponse['data']['display_url'];
        }
      } catch (e) {
        debugPrint('Error uploading image to ImgBB: $e');
      }
      return null;
    }

    if (_newImage != null) {
      photoUrl = await uploadToImgBB(_newImage!);
    }
    if (_newCoverImage != null) {
      coverUrl = await uploadToImgBB(_newCoverImage!);
    }

    final updateData = {
      'name': _nameController.text.trim(),
      'professionalTitle': _titleController.text.trim(),
      'bio': _bioController.text.trim(),
      'fieldOfStudy': _fieldController.text.trim(),
      'studyLevel': _levelController.text.trim(),
      'university': _universityController.text.trim(),
      'country': _countryController.text.trim(),
      'city': _cityController.text.trim(),
      'skills': _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };

    if (photoUrl != null) {
      updateData['photoURL'] = photoUrl;
    }
    if (coverUrl != null) {
      updateData['coverPhoto'] = coverUrl;
    }

    try {
      await context.read<AuthProvider>().updateProfile(updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green),
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
                child: Column(
                  children: [
                    // Cover photo preview
                    GestureDetector(
                      onTap: () => _pickImage(isCover: true),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _newCoverImage != null 
                              ? DecorationImage(image: FileImage(_newCoverImage!), fit: BoxFit.cover)
                              : (widget.user.coverPhoto.isNotEmpty ? DecorationImage(image: NetworkImage(widget.user.coverPhoto), fit: BoxFit.cover) : null),
                        ),
                        child: _newCoverImage == null && widget.user.coverPhoto.isEmpty
                            ? const Center(child: Icon(Icons.add_a_photo, color: Colors.grey))
                            : const Align(alignment: Alignment.bottomRight, child: Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.edit, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _pickImage(isCover: false),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _newImage != null 
                                ? FileImage(_newImage!) as ImageProvider
                                : (widget.user.photoURL.isNotEmpty ? NetworkImage(widget.user.photoURL) : null),
                            child: _newImage == null && widget.user.photoURL.isEmpty
                                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Informations de base", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              KairoTextField(controller: _nameController, hintText: 'Nom Complet', prefixIcon: PhosphorIcons.user()),
              const SizedBox(height: 12),
              KairoTextField(controller: _titleController, hintText: 'Titre professionnel (ex: Développeur Flutter)', prefixIcon: PhosphorIcons.briefcase()),
              const SizedBox(height: 12),
              KairoTextField(controller: _bioController, hintText: 'Bio rapide...', prefixIcon: PhosphorIcons.textAa()),
              const SizedBox(height: 24),
              
              const Text("Études & Localisation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              KairoTextField(controller: _fieldController, hintText: 'Filière d\'études', prefixIcon: PhosphorIcons.student()),
              const SizedBox(height: 12),
              KairoTextField(controller: _levelController, hintText: 'Niveau (ex: Bac+3, Master)', prefixIcon: PhosphorIcons.certificate()),
              const SizedBox(height: 12),
              KairoTextField(controller: _universityController, hintText: 'Université / École', prefixIcon: PhosphorIcons.bank()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: KairoTextField(controller: _cityController, hintText: 'Ville', prefixIcon: PhosphorIcons.buildings())),
                  const SizedBox(width: 8),
                  Expanded(child: KairoTextField(controller: _countryController, hintText: 'Pays', prefixIcon: PhosphorIcons.mapPin())),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Compétences", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              KairoTextField(controller: _skillsController, hintText: 'Séparées par des virgules...', prefixIcon: PhosphorIcons.lightning()),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
