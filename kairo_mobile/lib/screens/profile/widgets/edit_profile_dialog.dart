import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/kairo_text_field.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;
  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _fieldController = TextEditingController();
  final _levelController = TextEditingController();
  final _universityController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  File? _newImage;
  File? _newCoverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(widget.user);
  }

  void _loadUserData(UserModel user) {
    _nameController.text = user.name;
    _titleController.text = user.professionalTitle;
    _bioController.text = user.bio;
    _fieldController.text = user.fieldOfStudy;
    _levelController.text = user.studyLevel;
    _universityController.text = user.university;
    _countryController.text = user.country;
    _cityController.text = user.city;
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
    super.dispose();
  }

  Future<void> _pickImage({bool isCover = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recadrer',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isCover
                ? CropAspectRatioPreset.ratio16x9
                : CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Recadrer', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          if (isCover) {
            _newCoverImage = File(croppedFile.path);
          } else {
            _newImage = File(croppedFile.path);
          }
        });
      }
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
          const SnackBar(
            content: Text('Profil mis à jour !'),
            backgroundColor: Colors.green,
          ),
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
                  const Text(
                    'Éditer mon profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                              ? DecorationImage(
                                  image: FileImage(_newCoverImage!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.user.coverPhoto.isNotEmpty
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          widget.user.coverPhoto,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            _newCoverImage == null &&
                                widget.user.coverPhoto.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey,
                                ),
                              )
                            : Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).cardColor,
                                    shadows: [
                                      Shadow(
                                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                                : (widget.user.photoURL.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          widget.user.photoURL,
                                        )
                                      : null),
                            child:
                                _newImage == null &&
                                    widget.user.photoURL.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Informations de base",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              KairoTextField(
                controller: _nameController,
                hintText: 'Nom Complet',
                prefixIcon: PhosphorIcons.user(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _titleController,
                hintText: 'Titre professionnel (ex: Développeur Flutter)',
                prefixIcon: PhosphorIcons.briefcase(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _bioController,
                hintText: 'Bio rapide...',
                prefixIcon: PhosphorIcons.textAa(),
                maxLength: 160,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              const Text(
                "Études & Localisation",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              KairoTextField(
                controller: _fieldController,
                hintText: 'Filière d\'études',
                prefixIcon: PhosphorIcons.student(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _levelController,
                hintText: 'Niveau (ex: Bac+3, Master)',
                prefixIcon: PhosphorIcons.certificate(),
              ),
              const SizedBox(height: 12),
              KairoTextField(
                controller: _universityController,
                hintText: 'Université / École',
                prefixIcon: PhosphorIcons.bank(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KairoTextField(
                      controller: _cityController,
                      hintText: 'Ville',
                      prefixIcon: PhosphorIcons.buildings(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KairoTextField(
                      controller: _countryController,
                      hintText: 'Pays (ex: 🇫🇷 France)',
                      prefixIcon: PhosphorIcons.mapPin(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).cardColor,
                        ),
                      )
                    : Text(
                        'Sauvegarder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
