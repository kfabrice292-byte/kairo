import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/activity_logger_service.dart';
import '../../core/utils/cv_generator.dart';
import '../../core/utils/payment_utils.dart';
import '../../core/services/ats_scoring_service.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:pdf/pdf.dart';
import 'pdf_preview_screen.dart';

class CVEditScreen extends StatefulWidget {
  final UserModel user;

  const CVEditScreen({super.key, required this.user});

  @override
  State<CVEditScreen> createState() => _CVEditScreenState();
}

class _CVEditScreenState extends State<CVEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  String _selectedTemplate = 'moderne';
  String _selectedDestination = 'burkina';
  int _selectedColorIndex = 0;
  final List<Map<String, dynamic>> _availableColors = [
    {'color': const Color(0xFF263238), 'pdfColor': PdfColors.blueGrey900},
    {'color': const Color(0xFF1A237E), 'pdfColor': PdfColors.indigo900},
    {'color': const Color(0xFF004D40), 'pdfColor': PdfColors.teal900},
    {'color': const Color(0xFF880E4F), 'pdfColor': PdfColors.pink900},
    {'color': const Color(0xFFE65100), 'pdfColor': PdfColors.orange900},
    {'color': const Color(0xFF4A148C), 'pdfColor': PdfColors.purple900},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _titleController = TextEditingController(
      text: widget.user.lastCvTitle.isNotEmpty
          ? widget.user.lastCvTitle
          : widget.user.professionalTitle,
    );
    _bioController = TextEditingController(
      text: widget.user.bio.isNotEmpty 
          ? widget.user.bio 
          : widget.user.lastCvBio,
    );
    if (widget.user.lastCvTemplate.isNotEmpty) {
      _selectedTemplate = widget.user.lastCvTemplate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Personnaliser le CV',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAtsScoreCard(),
              const SizedBox(height: 24),
              const Text(
                'Nom complet',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Requis' : null,
              ),

              const SizedBox(height: 20),
              const Text(
                'Titre professionnel visé',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Développeur Flutter Senior',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // validator: (val) => (val == null || val.isEmpty) ? 'Requis' : null,
              ),

              const SizedBox(height: 20),
              const Text(
                'Résumé (Bio)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Thème de couleur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final colorData = _availableColors[index];
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorData['color'] as Color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: AppColors.primary, width: 3) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Choisissez un modèle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Sélection du modèle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTemplateCard(
                      'Classique',
                      'classique',
                      PhosphorIcons.fileText(),
                    ),
                    const SizedBox(width: 12),
                    _buildTemplateCard(
                      'Exécutif',
                      'executif',
                      PhosphorIcons.briefcase(),
                    ),
                    const SizedBox(width: 12),
                    _buildTemplateCard(
                      'Moderne',
                      'moderne',
                      PhosphorIcons.fileCode(),
                    ),
                    const SizedBox(width: 12),
                    _buildTemplateCard(
                      'Créatif',
                      'creatif',
                      PhosphorIcons.palette(),
                    ),
                    const SizedBox(width: 12),
                    _buildTemplateCard(
                      'Minimaliste',
                      'minimaliste',
                      PhosphorIcons.columns(),
                    ),
                    const SizedBox(width: 12),
                    _buildTemplateCard(
                      'Tech',
                      'tech',
                      PhosphorIcons.cpu(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Cible géographique',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDestination,
                decoration: InputDecoration(
                  prefixIcon: Icon(PhosphorIcons.globe()),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'burkina', child: Text('Burkina Faso & UEMOA')),
                  DropdownMenuItem(value: 'international', child: Text('International (Anonymisé)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDestination = val);
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final String currentName = _nameController.text.trim();
                      final String currentTitle = _titleController.text.trim();
                      final String currentBio = _bioController.text.trim();

                      // On crée une copie temporaire de l'utilisateur avec les nouvelles données
                      final customUser = UserModel(
                        uid: widget.user.uid,
                        name: currentName,
                        professionalTitle: currentTitle,
                        bio: currentBio,
                        email: widget.user.email,
                        photoURL: widget.user.photoURL,
                        city: widget.user.city,
                        country: widget.user.country,
                        university: widget.user.university,
                        fieldOfStudy: widget.user.fieldOfStudy,
                        studyLevel: widget.user.studyLevel,
                        skills: widget.user.skills,
                        experiences: widget.user.experiences,
                        educations: widget.user.educations,
                        languages: widget.user.languages,
                        certifications: widget.user.certifications,
                        phone: widget.user.phone,
                      );

                      // Save params to Firestore silently
                      context.read<AuthProvider>().updateProfile({
                        'lastCvTitle': currentTitle,
                        'lastCvBio': currentBio,
                        'lastCvTemplate': _selectedTemplate,
                      });

                      ActivityLoggerService.logAction(
                        actionType: ActivityLoggerService.ACTION_GENERATE_CV,
                        metadata: {'template': _selectedTemplate, 'destination': _selectedDestination}
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(
                            user: customUser,
                            title: 'Aperçu du CV',
                            generatePdf: () => CVGenerator.generateCV(
                              customUser,
                              template: _selectedTemplate,
                              destination: _selectedDestination,
                              customColor: _availableColors[_selectedColorIndex]['pdfColor'] as PdfColor,
                            ),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir les champs obligatoires (Nom et Titre).'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Générer mon CV PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Theme.of(context).iconTheme.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String value, IconData icon) {
    final isSelected = _selectedTemplate == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTemplate = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtsScoreCard() {
    final evaluation = AtsScoringService.evaluateCV(widget.user);
    final int score = evaluation['score'];
    final String grade = evaluation['grade'];
    final List<String> feedback = List<String>.from(evaluation['feedback']);

    Color scoreColor = Colors.red;
    if (score >= 80) scoreColor = Colors.green;
    else if (score >= 60) scoreColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIcons.chartLineUp(), color: scoreColor, size: 28),
              const SizedBox(width: 12),
              Text(
                'Score ATS : $score/100',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ce score indique comment les algorithmes de recrutement évaluent votre profil.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          if (feedback.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            ...feedback.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.warningCircle(), size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
