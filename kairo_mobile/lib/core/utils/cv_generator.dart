import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import 'cv_templates.dart';


class CVGenerator {
  static Future<Uint8List> generateCV(
    UserModel user, {
    String template = 'moderne',
    String destination = 'burkina',
    PdfColor? customColor,
  }) async {
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
        italic: fontItalic,
      ),
    );

    final primaryColor = customColor ?? (template == 'creatif'
        ? PdfColors.purple800
        : (template == 'classique'
              ? PdfColors.blueGrey800
              : PdfColors.blueGrey900)); // Default to elegant dark grey instead of bright orange

    pw.MemoryImage? profileImage;
    if (user.photoURL.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(user.photoURL)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // ignore image if failed
      }
    }

    
    if (template == 'minimaliste') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => CVTemplates.buildMinimaliste(user, profileImage, primaryColor, destination),
        )
      );
    } else if (template == 'harvard' || template == 'classique') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
          build: (pw.Context context) => CVTemplates.buildHarvard(user, profileImage, destination),
        )
      );
    } else if (template == 'executif') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(48),
          build: (pw.Context context) => CVTemplates.buildExecutif(user, profileImage, primaryColor, destination),
        )
      );
    } else if (template == 'creatif') {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: CVTemplates.buildCreatifTheme(primaryColor, user, profileImage, destination),
          build: (pw.Context context) => CVTemplates.buildCreatifContent(user, primaryColor),
        )
      );
    } else if (template == 'tech') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => CVTemplates.buildTech(user, profileImage, primaryColor, destination),
        )
      );
    } else {
      // Default / Moderne
      pdf.addPage(
        pw.MultiPage(
          pageTheme: CVTemplates.buildModerneTheme(primaryColor, user, profileImage, destination),
          build: (pw.Context context) => CVTemplates.buildModerneContent(user, primaryColor),
        )
      );
    }

    return pdf.save();
  }
}
