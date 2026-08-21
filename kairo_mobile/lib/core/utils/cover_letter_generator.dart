import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/user_model.dart';

class CoverLetterGenerator {
  static Future<Uint8List> generate(
    UserModel user, 
    String template, 
    String contentText, 
    String companyName, 
    {PdfColor? customColor}
  ) async {
    final pdf = pw.Document();
    
    final primaryColor = customColor ?? (template == 'creatif'
        ? PdfColors.purple800
        : (template == 'classique'
              ? PdfColors.blueGrey800
              : PdfColors.blueGrey900));

    // Initialiser les dates en français (si possible, sinon on utilise un format standard)
    String dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());

    // Parser le contenu de l'IA pour extraire l'Objet
    String objetText = '';
    String bodyText = contentText;

    final lines = contentText.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().startsWith('objet') || lines[i].toLowerCase().startsWith('objet:')) {
        objetText = lines[i].trim();
        // Remove the objet line from body
        lines.removeAt(i);
        bodyText = lines.join('\n').trim();
        break;
      }
    }
    
    // Si l'objet n'a pas été trouvé avec "Objet :", on cherche la première ligne courte.
    if (objetText.isEmpty && lines.isNotEmpty && lines[0].length < 100 && !lines[0].toLowerCase().contains('madame')) {
       objetText = lines[0].trim();
       lines.removeAt(0);
       bodyText = lines.join('\n').trim();
    }
    
    // Ensure body starts clean
    bodyText = bodyText.replaceFirst(RegExp(r'^\s+'), '');

    // Layouts
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: template == 'moderne' || template == 'creatif' 
            ? pw.EdgeInsets.zero 
            : const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          
          if (template == 'classique' || template == 'harvard') {
            final isHarvard = template == 'harvard';
            final baseFont = isHarvard ? pw.Font.times() : null;
            final boldFont = isHarvard ? pw.Font.timesBold() : null;
            
            return [
              // EN-TÊTE : Emetteur (Gauche)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(user.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, font: boldFont)),
                      pw.Text(user.professionalTitle, style: pw.TextStyle(fontSize: 10, font: baseFont)),
                      pw.SizedBox(height: 4),
                      if (user.city.isNotEmpty || user.country.isNotEmpty)
                        pw.Text('${user.city}, ${user.country}', style: pw.TextStyle(fontSize: 10, font: baseFont)),
                      if (user.email.isNotEmpty)
                        pw.Text(user.email, style: pw.TextStyle(fontSize: 10, font: baseFont)),
                      if (user.phone.isNotEmpty)
                        pw.Text(user.phone, style: pw.TextStyle(fontSize: 10, font: baseFont)),
                    ],
                  ),
                  
                  // EN-TÊTE : Destinataire (Droite) + Date
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, font: boldFont)),
                      pw.SizedBox(height: 16),
                      pw.Text('${user.city.isNotEmpty ? user.city : "Ouagadougou"}, le $dateStr', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, font: baseFont)),
                    ]
                  )
                ]
              ),
              
              pw.SizedBox(height: 40),
              
              // OBJET
              if (objetText.isNotEmpty)
                pw.Text(
                  objetText,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, font: boldFont, decoration: pw.TextDecoration.underline),
                ),
                
              pw.SizedBox(height: 24),
              
              // CORPS
              pw.Text(
                bodyText,
                style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5, font: baseFont),
                textAlign: pw.TextAlign.justify,
              ),
              
              pw.SizedBox(height: 40),
              
              // SIGNATURE (Droite)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(user.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont)),
                  ]
                )
              )
            ];
          } 
          
          else if (template == 'moderne' || template == 'creatif') {
            return [
              // HEADER BANNER
              pw.Container(
                color: primaryColor,
                padding: const pw.EdgeInsets.all(40),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: template == 'creatif' ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            user.name.toUpperCase(),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: template == 'creatif' ? 24 : 20,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                            textAlign: template == 'creatif' ? pw.TextAlign.center : pw.TextAlign.left,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            user.professionalTitle,
                            style: pw.TextStyle(
                              color: PdfColors.grey200,
                              fontSize: 12,
                            ),
                            textAlign: template == 'creatif' ? pw.TextAlign.center : pw.TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // CONTACT BAR
              pw.Container(
                color: PdfColors.grey100,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    if (user.city.isNotEmpty)
                      pw.Text('${user.city}, ${user.country}', style: const pw.TextStyle(fontSize: 10)),
                    if (user.email.isNotEmpty)
                      pw.Text(user.email, style: const pw.TextStyle(fontSize: 10)),
                    if (user.phone.isNotEmpty)
                      pw.Text(user.phone, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              
              // CONTENT
              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('À l\'attention de :', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text('${user.city.isNotEmpty ? user.city : "Ouagadougou"}, le $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ]
                    ),
                    pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.SizedBox(height: 32),
                    
                    if (objetText.isNotEmpty) ...[
                      pw.Text(
                        objetText,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 24),
                    ],
                    
                    pw.Text(
                      bodyText,
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                      textAlign: pw.TextAlign.justify,
                    ),
                    
                    pw.SizedBox(height: 40),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(user.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    )
                  ]
                )
              )
            ];
          }
          
          else {
            // Minimaliste
            return [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          user.name.toUpperCase(),
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        if (user.professionalTitle.isNotEmpty)
                          pw.Text(user.professionalTitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (user.email.isNotEmpty)
                          pw.Text(user.email, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        if (user.phone.isNotEmpty)
                          pw.Text(user.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 32),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pour : ${companyName.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ]
              ),
              
              pw.SizedBox(height: 32),
              
              if (objetText.isNotEmpty) ...[
                pw.Text(
                  objetText,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: primaryColor),
                ),
                pw.SizedBox(height: 24),
              ],
              
              pw.Text(
                bodyText,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5, color: PdfColors.grey900),
                textAlign: pw.TextAlign.left,
              ),
              
              pw.SizedBox(height: 40),
              pw.Text(user.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ];
          }
        },
      )
    );

    return pdf.save();
  }
}
