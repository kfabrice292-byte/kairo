import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/activity_logger_service.dart';
import '../../core/utils/portfolio_generator.dart';
import '../../core/utils/payment_utils.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'pdf_preview_screen.dart';

class PortfolioEditScreen extends StatefulWidget {
  final UserModel user;

  const PortfolioEditScreen({super.key, required this.user});

  @override
  State<PortfolioEditScreen> createState() => _PortfolioEditScreenState();
}

class _PortfolioEditScreenState extends State<PortfolioEditScreen> {
  String _selectedTemplate = 'moderne';
  int _selectedColorIndex = 0;

  final List<Map<String, dynamic>> _availableColors = [
    {'color': const Color(0xFF263238), 'pdfColor': PdfColors.blueGrey900},
    {'color': const Color(0xFF1A237E), 'pdfColor': PdfColors.indigo900},
    {'color': const Color(0xFF004D40), 'pdfColor': PdfColors.teal900},
    {'color': const Color(0xFF880E4F), 'pdfColor': PdfColors.pink900},
    {'color': const Color(0xFFE65100), 'pdfColor': PdfColors.orange900},
    {'color': const Color(0xFF4A148C), 'pdfColor': PdfColors.purple900},
  ];

  Widget _buildTemplateCard(String title, String value, IconData icon) {
    final isSelected = _selectedTemplate == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTemplate = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primary.withValues(alpha: 0.1) 
                : Theme.of(context).cardColor,
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : null,
                  fontSize: 12,
                ),
              ),
            ],
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
          'Personnaliser le Portfolio',
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
            const Text(
              'Générez un portfolio professionnel pour mettre en valeur vos projets et réalisations.',
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 32),

            const Text(
              'Choisissez un modèle',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTemplateCard(
                  'Classique',
                  'classique',
                  PhosphorIcons.briefcase(),
                ),
                const SizedBox(width: 12),
                _buildTemplateCard(
                  'Moderne',
                  'moderne',
                  PhosphorIcons.star(),
                ),
                const SizedBox(width: 12),
                _buildTemplateCard(
                  'Minimaliste',
                  'minimaliste',
                  PhosphorIcons.columns(),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text(
              'Thème de couleur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
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
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                      ActivityLoggerService.logAction(
                        actionType: ActivityLoggerService.ACTION_GENERATE_PORTFOLIO,
                        metadata: {'template': _selectedTemplate}
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(
                            user: widget.user,
                            title: 'Aperçu du Portfolio',
                            generatePdf: () => PortfolioGenerator.generatePortfolio(
                              widget.user,
                              template: _selectedTemplate,
                              customColor: _availableColors[_selectedColorIndex]['pdfColor'] as PdfColor,
                            ),
                          ),
                        ),
                      );
                },
                icon: Icon(PhosphorIcons.filePdf(), color: Theme.of(context).cardColor),
                label: Text(
                  'Générer le Portfolio',
                  style: TextStyle(
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
        ),
      ),
    );
  }
}
