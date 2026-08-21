import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class PortfolioGenerator {
  static Future<Uint8List> generatePortfolio(
    UserModel user, {
    String template = 'moderne',
    PdfColor? customColor,
  }) async {
    final pdf = pw.Document();
    
    // Branding colors
    final primaryColor = customColor ?? (template == 'creatif'
        ? PdfColors.purple800
        : (template == 'classique'
              ? PdfColors.blueGrey800
              : PdfColors.blueGrey900));
    final accentColor = PdfColors.orange800; // Keep Kaïro orange as an accent for some elements
    final surfaceColor = PdfColor.fromInt(0xFFF8FAFC);

    pw.MemoryImage? profileImage;
    if (user.photoURL.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(user.photoURL));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // ============================================
    // COVER PAGE
    // ============================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          if (template == 'classique') {
            return pw.Container(
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('PORTFOLIO PROFESSIONNEL', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16, letterSpacing: 2)),
                  pw.SizedBox(height: 40),
                  pw.Text(user.name.toUpperCase(), style: pw.TextStyle(color: primaryColor, fontSize: 40, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
                  pw.SizedBox(height: 10),
                  pw.Text(user.professionalTitle, style: pw.TextStyle(color: PdfColors.grey800, fontSize: 20, fontStyle: pw.FontStyle.italic, font: pw.Font.times())),
                  pw.SizedBox(height: 60),
                  pw.Divider(color: primaryColor),
                  pw.SizedBox(height: 60),
                  pw.Text('${user.email} | ${user.phone}', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('${user.city}, ${user.country}', style: const pw.TextStyle(fontSize: 12)),
                ]
              )
            );
          } else if (template == 'minimaliste') {
             return pw.Container(
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 100),
                  pw.Text(user.name.toUpperCase(), style: pw.TextStyle(color: primaryColor, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                  pw.Text(user.professionalTitle, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 18)),
                  pw.SizedBox(height: 40),
                  pw.Container(width: 40, height: 2, color: primaryColor),
                  pw.Spacer(),
                  pw.Text(user.email, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(user.phone, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('${user.city}, ${user.country}', style: const pw.TextStyle(fontSize: 10)),
                ]
              )
            );
          } else {
            // Moderne / Creatif
            return pw.Container(
              color: primaryColor,
              width: double.infinity,
              height: double.infinity,
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 60, height: 4, color: PdfColors.white),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'PORTFOLIO PROFESSIONNEL',
                    style: pw.TextStyle(
                      color: const PdfColor(1, 1, 1, 0.7),
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    user.name.toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    user.professionalTitle,
                    style: pw.TextStyle(
                      color: PdfColors.grey200,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Spacer(),
                  if (user.city.isNotEmpty || user.email.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CONTACT',
                          style: pw.TextStyle(
                            color: const PdfColor(1, 1, 1, 0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          user.email,
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${user.city}, ${user.country}',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                        ),
                        pw.SizedBox(height: 24),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'https://kairo.app/p/${user.uid}',
                          width: 50,
                          height: 50,
                          color: PdfColors.white,
                        ),
                      ],
                    ),
                ],
              ),
            );
          }
        },
      ),
    );

    // PAGE 2: ABOUT & SKILLS
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          final titleFont = template == 'classique' ? pw.Font.timesBold() : null;
          final baseFont = template == 'classique' ? pw.Font.times() : null;
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('À PROPOS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont)),
              pw.Container(width: 40, height: 2, color: primaryColor, margin: const pw.EdgeInsets.only(top: 8, bottom: 30)),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null && template != 'classique') ...[
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.rectangle,
                        borderRadius: pw.BorderRadius.circular(16),
                        image: pw.DecorationImage(
                          image: profileImage,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 40),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Biographie',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          user.bio.isEmpty ? 'Aucune description fournie.' : user.bio,
                          style: pw.TextStyle(fontSize: 11, lineSpacing: 1.8, color: PdfColors.grey800, font: baseFont),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (user.skills.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('EXPERTISE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont)),
                          pw.SizedBox(height: 12),
                          ...user.skills.map((s) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Text('• ${s.name}', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, font: baseFont)),
                          )),
                        ]
                      )
                    ),
                  if (user.languages.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LANGUES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont)),
                          pw.SizedBox(height: 12),
                          ...user.languages.map((l) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Text('• ${l.name} (${l.level}/5)', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, font: baseFont)),
                          )),
                        ]
                      )
                    ),
                ]
              )
            ]
          );
        }
      )
    );

    // PAGE 3: PORTFOLIO PROJECTS
    if (user.portfolioProjects.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            final titleFont = template == 'classique' ? pw.Font.timesBold() : null;
            final baseFont = template == 'classique' ? pw.Font.times() : null;
            
            return [
              pw.Text('PORTFOLIO & RÉALISATIONS', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont)),
              pw.Container(width: 40, height: 2, color: primaryColor, margin: const pw.EdgeInsets.only(top: 8, bottom: 30)),
              
              pw.Wrap(
                spacing: 30,
                runSpacing: 30,
                children: user.portfolioProjects.map((proj) {
                  return pw.Container(
                    width: 200,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // IMAGE PLACEHOLDER OR REAL IMAGE
                        pw.Container(
                          height: 120,
                          width: double.infinity,
                          decoration: pw.BoxDecoration(
                            color: surfaceColor,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Center(
                            child: pw.Text('Aperçu du projet', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10, font: baseFont)),
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          proj.title,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor, font: titleFont),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          proj.description,
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 1.5, font: baseFont),
                          maxLines: 3,
                        ),
                        if (proj.link.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            proj.link,
                            style: pw.TextStyle(fontSize: 9, color: accentColor, decoration: pw.TextDecoration.underline, font: baseFont),
                          ),
                        ]
                      ],
                    ),
                  );
                }).toList(),
              ),
            ];
          },
        ),
      );
    }
    
    return pdf.save();
  }
}
