import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/payment_utils.dart';

import '../../core/services/content_generator_service.dart';
import '../../core/services/activity_logger_service.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import '../../core/utils/cover_letter_generator.dart';
import 'pdf_preview_screen.dart';
class CoverLetterScreen extends StatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _notesController = TextEditingController();
  final _resultController = TextEditingController();

  bool _isLoading = false;
  bool _isGenerated = false;
  String _selectedTemplate = 'classique'; // Default to classique for Burkina
  String _employerType = 'Entreprise Privée';
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
  void dispose() {
    _companyController.dispose();
    _jobTitleController.dispose();
    _notesController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _generateLetter() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final letter = await ContentGeneratorService.generateCoverLetter(
      user: user,
      companyName: _companyController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      jobDescription: '',
      additionalNotes: _notesController.text.trim(),
      employerType: _employerType,
    );

    if (mounted) {
      setState(() {
        _resultController.text = letter;
        _isGenerated = true;
        _isLoading = false;
      });
    }
    
    ActivityLoggerService.logAction(
      actionType: ActivityLoggerService.ACTION_GENERATE_LETTER,
      metadata: {'company': _companyController.text.trim()}
    );
  }

  
  Future<void> _exportPdf() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    final text = _resultController.text;
    if (text.isEmpty) return;

    ActivityLoggerService.logAction(
      actionType: ActivityLoggerService.ACTION_GENERATE_LETTER,
      metadata: {'template': _selectedTemplate}
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          user: user,
          title: 'Aperçu de la Lettre',
          generatePdf: () => CoverLetterGenerator.generate(
            user,
            _selectedTemplate,
            text,
            _companyController.text.trim(),
            customColor: _availableColors[_selectedColorIndex]['pdfColor'] as PdfColor,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lettre de Motivation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isGenerated) ...[
              const Text(
                'Générez une lettre professionnelle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Indiquez les détails du poste, notre système s\'occupe de rédiger une lettre personnalisée basée sur votre profil Kaïro.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'entreprise',
                        prefixIcon: Icon(PhosphorIcons.buildings()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jobTitleController,
                      decoration: InputDecoration(
                        labelText: 'Titre du poste',
                        prefixIcon: Icon(PhosphorIcons.briefcase()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _employerType,
                      decoration: InputDecoration(
                        labelText: 'Type d\'employeur',
                        prefixIcon: Icon(PhosphorIcons.buildings()),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Entreprise Privée', child: Text('Entreprise Privée / Startup')),
                        DropdownMenuItem(value: 'Administration Publique', child: Text('Administration Publique (Burkina)')),
                        DropdownMenuItem(value: 'ONG', child: Text('ONG / Organisme International')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _employerType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Informations complémentaires (Optionnel)',
                        hintText:
                            'ex: J\'ai beaucoup aimé votre dernier projet...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTemplate,
                      decoration: InputDecoration(
                        labelText: 'Modèle de la lettre (pour assortir au CV)',
                        prefixIcon: Icon(PhosphorIcons.palette()),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'classique', child: Text('Classique / Burkina (Recommandé)')),
                        DropdownMenuItem(value: 'moderne', child: Text('Moderne Premium')),
                        DropdownMenuItem(value: 'minimaliste', child: Text('Minimaliste Tech')),
                        DropdownMenuItem(value: 'harvard', child: Text('Harvard (Académique)')),
                        DropdownMenuItem(value: 'creatif', child: Text('Créatif')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTemplate = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thème de couleur',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateLetter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).cardColor,
                                ),
                              )
                            : Text(
                                'Générer la lettre',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).cardColor,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Votre Lettre',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isGenerated = false;
                        _resultController.clear();
                      });
                    },
                    icon: Icon(PhosphorIcons.arrowCounterClockwise(), size: 16),
                    label: const Text('Refaire'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resultController,
                maxLines: null,
                minLines: 10,
                decoration: InputDecoration(
                  fillColor: Theme.of(context).cardColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: Icon(
                    PhosphorIcons.downloadSimple(),
                    color: Theme.of(context).cardColor,
                  ),
                  label: Text(
                    'Exporter en PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
