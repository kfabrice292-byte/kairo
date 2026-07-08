import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';

class PortfolioGenerator {
  static Future<void> generatePortfolio(UserModel user) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PORTFOLIO',
                    style: pw.TextStyle(
                      color: PdfColors.purple800,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    user.name.toUpperCase(),
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Généré automatiquement par Kaïro depuis vos expériences et projets.',
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 30),
            if (user.experiences.isNotEmpty) ...[
              pw.Text(
                'EXPÉRIENCES PROFESSIONNELLES',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.purple800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              ...user.experiences.map(
                (exp) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        exp.title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${exp.organization} • ${exp.period}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (exp.description.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          exp.description,
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            pw.Text(
              'PROJETS & RÉALISATIONS',
              style: pw.TextStyle(
                fontSize: 16,
                color: PdfColors.purple800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Text(
              'Retrouvez mes projets détaillés sur mon profil Kaïro.',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Portfolio_${user.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
