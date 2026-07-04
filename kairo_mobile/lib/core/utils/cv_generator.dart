import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';

class CVGenerator {
  static Future<void> generateAndPrintCV(UserModel user, {String template = 'moderne'}) async {
    final pdf = pw.Document();

    final primaryColor = template == 'creatif' ? PdfColors.purple800 : (template == 'classique' ? PdfColors.blueGrey800 : PdfColors.orange800);

    pw.MemoryImage? profileImage;
    if (user.photoURL.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(user.photoURL));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // ignore image if failed
      }
    }

    if (template == 'moderne') {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // SIDEBAR
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(24),
                  color: primaryColor,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (profileImage != null)
                        pw.Container(
                          width: 100,
                          height: 100,
                          margin: const pw.EdgeInsets.only(bottom: 20),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                      pw.Text(
                        user.name.toUpperCase(),
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        user.professionalTitle,
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 24),
                      if (user.city.isNotEmpty || user.country.isNotEmpty) ...[
                        pw.Text('LOCALISATION', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('${user.city}, ${user.country}', style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                        pw.SizedBox(height: 16),
                      ],
                      if (user.skills.isNotEmpty) ...[
                        pw.Divider(color: PdfColors.white, thickness: 0.5),
                        pw.SizedBox(height: 16),
                        pw.Text('COMPÉTENCES', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        ...user.skills.map((s) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text('• $s', style: pw.TextStyle(color: PdfColors.grey200, fontSize: 10)),
                        )),
                      ],
                    ],
                  ),
                ),
                // MAIN CONTENT
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(32),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (user.bio.isNotEmpty) ...[
                          pw.Text('PROFIL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.SizedBox(height: 8),
                          pw.Text(user.bio, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey800, lineSpacing: 1.5)),
                          pw.SizedBox(height: 24),
                        ],
                        if (user.experiences.isNotEmpty) ...[
                          pw.Text('EXPÉRIENCES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.SizedBox(height: 12),
                          ...user.experiences.map((exp) => pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 12),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(exp.title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                                    pw.Text(exp.period, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(exp.organization, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.orange800)),
                                if (exp.description.isNotEmpty) ...[
                                  pw.SizedBox(height: 4),
                                  pw.Text(exp.description, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                                ],
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Classique & Creatif Layout
      final headerAlignment = template == 'classique' ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: headerAlignment,
                        children: [
                          pw.Text(
                            user.name.toUpperCase(),
                            style: pw.TextStyle(fontSize: template == 'creatif' ? 28 : 24, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                          if (user.professionalTitle.isNotEmpty)
                            pw.Text(user.professionalTitle, style: pw.TextStyle(fontSize: 16, color: PdfColors.grey800)),
                          pw.SizedBox(height: 8),
                          if (user.city.isNotEmpty || user.country.isNotEmpty)
                            pw.Text('${user.city}, ${user.country}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                        ],
                      ),
                      if (profileImage != null)
                        pw.Container(
                          width: 80,
                          height: 80,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                if (user.bio.isNotEmpty) ...[
                  pw.Text('PROFIL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Text(user.bio, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5)),
                  pw.SizedBox(height: 20),
                ],
                if (user.skills.isNotEmpty) ...[
                  pw.Text('COMPÉTENCES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills.map((s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Text(s, style: const pw.TextStyle(fontSize: 10)),
                    )).toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (user.experiences.isNotEmpty) ...[
                  pw.Text('EXPÉRIENCES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 12),
                  ...user.experiences.map((exp) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(exp.title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text(exp.period, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(exp.organization, style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800)),
                        if (exp.description.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(exp.description, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                        ],
                      ],
                    ),
                  )),
                ],
              ],
            );
          },
        ),
      );
    }

    // Using printing package to preview and share/print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'CV_${user.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
