import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/cv_generator.dart';

class CVEditScreen extends StatefulWidget {
  final UserModel user;

  const CVEditScreen({super.key, required this.user});

  @override
  State<CVEditScreen> createState() => _CVEditScreenState();
}

class _CVEditScreenState extends State<CVEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late String _title;
  late String _bio;
  String _selectedTemplate = 'moderne';

  @override
  void initState() {
    super.initState();
    _name = widget.user.name;
    _title = widget.user.lastCvTitle.isNotEmpty ? widget.user.lastCvTitle : widget.user.professionalTitle;
    _bio = widget.user.lastCvBio.isNotEmpty ? widget.user.lastCvBio : widget.user.bio;
    if (widget.user.lastCvTemplate.isNotEmpty) {
      _selectedTemplate = widget.user.lastCvTemplate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Personnaliser le CV', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adaptez votre profil pour ce CV spécifique. Vos modifications ici ne changeront pas votre profil Kaïro public.', style: TextStyle(color: Colors.grey, height: 1.4)),
              const SizedBox(height: 24),
              
              const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (val) => _name = val ?? '',
              ),
              
              const SizedBox(height: 20),
              const Text('Titre professionnel visé', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  hintText: 'Ex: Développeur Flutter Senior',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (val) => _title = val ?? '',
              ),

              const SizedBox(height: 20),
              const Text('Résumé (Bio)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _bio,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (val) => _bio = val ?? '',
              ),
              
              const SizedBox(height: 32),
              const Text('Choisissez un modèle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              
              // Sélection du modèle
              Row(
                children: [
                  _buildTemplateOption('Classique', 'classique', PhosphorIcons.fileText()),
                  const SizedBox(width: 12),
                  _buildTemplateOption('Moderne', 'moderne', PhosphorIcons.fileCode()),
                  const SizedBox(width: 12),
                  _buildTemplateOption('Créatif', 'creatif', PhosphorIcons.palette()),
                ],
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      
                      // On crée une copie temporaire de l'utilisateur avec les nouvelles données
                        final customUser = UserModel(
                          uid: widget.user.uid,
                          name: _name,
                          professionalTitle: _title,
                          bio: _bio,
                          email: widget.user.email,
                          photoURL: widget.user.photoURL,
                          city: widget.user.city,
                          country: widget.user.country,
                          university: widget.user.university,
                          fieldOfStudy: widget.user.fieldOfStudy,
                          studyLevel: widget.user.studyLevel,
                          skills: widget.user.skills,
                          experiences: widget.user.experiences,
                        );

                        // Save params to Firestore silently
                        context.read<AuthProvider>().updateProfile({
                          'lastCvTitle': _title,
                          'lastCvBio': _bio,
                          'lastCvTemplate': _selectedTemplate,
                        });

                        CVGenerator.generateAndPrintCV(customUser, template: _selectedTemplate);
                      }
                    },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text('Générer mon CV PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String title, String value, IconData icon) {
    final isSelected = _selectedTemplate == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTemplate = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.white,
            border: Border.all(color: isSelected ? const Color(0xFFF97316) : Colors.grey.shade300, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFF97316) : Colors.grey),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFF97316) : Colors.grey.shade700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
