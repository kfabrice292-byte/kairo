import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/user_model.dart';

class CVTemplates {
  
  // ---------------------------------------------------------
  // HELPERS POUR DESIGN PREMIUM
  // ---------------------------------------------------------
  
  static pw.Widget _buildBullet() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, right: 8),
      width: 4,
      height: 4,
      decoration: const pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: PdfColors.black,
      ),
    );
  }

  static pw.Widget _buildColoredBullet(PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, right: 8),
      width: 4,
      height: 4,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: color,
      ),
    );
  }

  static pw.Widget _buildMinimalisteSectionTitle(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(left: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: color, width: 4)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color, letterSpacing: 1),
      ),
    );
  }

  // ---------------------------------------------------------
  // 1. MODERNE PREMIUM (Sidebar discrète, Typographie forte)
  // ---------------------------------------------------------
  static pw.PageTheme buildModerneTheme(PdfColor primaryColor, UserModel user, pw.MemoryImage? profileImage, String destination) {
    final bool isDarkColor = primaryColor.luminance < 0.5;
    final PdfColor sidebarTextColor = isDarkColor ? PdfColors.white : PdfColors.grey900;
    final PdfColor sidebarSubtitleColor = isDarkColor ? PdfColors.grey300 : PdfColors.grey700;

    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(left: 200, top: 32, right: 32, bottom: 32),
      buildBackground: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Row(
            children: [
              pw.Container(width: 170, color: primaryColor),
              pw.Expanded(child: pw.Container(color: PdfColors.white)),
            ]
          )
        );
      },
      buildForeground: (pw.Context context) {
        if (context.pageNumber == 1) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 170,
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (profileImage != null && destination != 'international')
                        pw.Container(
                          width: 90,
                          height: 90,
                          margin: const pw.EdgeInsets.only(bottom: 20),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(
                              image: profileImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      pw.Text(
                        user.name.toUpperCase(),
                        style: pw.TextStyle(
                          color: sidebarTextColor,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        user.professionalTitle,
                        style: pw.TextStyle(
                          color: sidebarSubtitleColor,
                          fontSize: 11,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 30),

                      // COORDONNEES
                      if (user.city.isNotEmpty || user.country.isNotEmpty || user.email.isNotEmpty || user.phone.isNotEmpty) ...[
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            'CONTACT',
                            style: pw.TextStyle(
                              color: sidebarTextColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        if (user.city.isNotEmpty)
                          pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text('${user.city}, ${user.country}', style: pw.TextStyle(color: sidebarSubtitleColor, fontSize: 9)),
                          ),
                        if (user.phone.isNotEmpty)
                          pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(user.phone, style: pw.TextStyle(color: sidebarSubtitleColor, fontSize: 9)),
                          ),
                        if (user.email.isNotEmpty)
                          pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(user.email, style: pw.TextStyle(color: sidebarSubtitleColor, fontSize: 9)),
                          ),
                        pw.SizedBox(height: 20),
                      ],

                      // COMPETENCES
                      if (user.skills.isNotEmpty) ...[
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            'COMPÉTENCES',
                            style: pw.TextStyle(
                              color: sidebarTextColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        ...user.skills.take(12).map(
                          (s) => pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  margin: const pw.EdgeInsets.only(top: 3, right: 6),
                                  width: 3,
                                  height: 3,
                                  decoration: pw.BoxDecoration(
                                    shape: pw.BoxShape.circle,
                                    color: sidebarSubtitleColor,
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Text(
                                    s.name,
                                    style: pw.TextStyle(
                                      color: sidebarTextColor,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 20),
                      ],

                      // LANGUES
                      if (user.languages.isNotEmpty) ...[
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            'LANGUES',
                            style: pw.TextStyle(
                              color: sidebarTextColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        ...user.languages.take(6).map((l) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              '${l.name} (${l.level}/5)',
                              style: pw.TextStyle(color: sidebarTextColor, fontSize: 9),
                            ),
                          ),
                        )),
                        pw.SizedBox(height: 20),
                      ],

                      // CENTRES D'INTERET
                      if (user.interests.isNotEmpty) ...[
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            'CENTRES D\'INTÉRÊT',
                            style: pw.TextStyle(
                              color: sidebarTextColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        ...user.interests.take(6).map((interest) => pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Align(
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              interest,
                              style: pw.TextStyle(color: sidebarTextColor, fontSize: 9),
                            ),
                          ),
                        )),
                        pw.SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ]
            )
          );
        }
        return pw.SizedBox();
      }
    );
  }

  static List<pw.Widget> buildModerneContent(UserModel user, PdfColor primaryColor) {
    return [
      // BIO
      if (user.bio.isNotEmpty) ...[
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 0.5)),
          ),
          child: pw.Text(
            'PROFIL',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          user.bio,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
            lineSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 28), // Espacement augmenté pour laisser respirer
      ],

      // EXPERIENCES
      if (user.experiences.isNotEmpty) ...[
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 0.5)),
          ),
          child: pw.Text(
            'EXPÉRIENCES PROFESSIONNELLES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        ...user.experiences.map(
          (exp) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp.title,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Text(
                      exp.period,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  exp.organization,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                if (exp.description.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    exp.description,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                      lineSpacing: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 8),
      ],

      // FORMATIONS
      if (user.educations.isNotEmpty) ...[
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 0.5)),
          ),
          child: pw.Text(
            'FORMATIONS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        ...user.educations.map(
          (edu) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        edu.title,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Text(
                      edu.period,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  edu.institution,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 8),
      ],

      // PROJETS & RÉALISATIONS
      if (user.portfolioProjects.isNotEmpty) ...[
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 0.5)),
          ),
          child: pw.Text(
            'PROJETS & RÉALISATIONS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
        ...user.portfolioProjects.map(
          (project) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  project.title,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  project.description,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                    lineSpacing: 1.4,
                  ),
                ),
                if (project.technologies.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Technologies : ${project.technologies.join(", ")}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: primaryColor,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    ];
  }

  // ---------------------------------------------------------
  // 2. MINIMALISTE TECH (Une colonne, Aéré, Épuré)
  // ---------------------------------------------------------
  static List<pw.Widget> buildMinimaliste(UserModel user, pw.MemoryImage? profileImage, PdfColor primaryColor, String destination) {
    return [
      // HEADER MINIMALISTE
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (profileImage != null && destination != 'international')
            pw.Container(
              width: 80,
              height: 80,
              margin: const pw.EdgeInsets.only(right: 24),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.rectangle,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  user.name.toUpperCase(),
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1.5),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  user.professionalTitle,
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700, letterSpacing: 1.2),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    if (user.city.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(right: 12), child: pw.Text('${user.city}, ${user.country}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
                    if (user.phone.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(right: 12), child: pw.Text(user.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
                    if (user.email.isNotEmpty) pw.Text(user.email, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ]
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 32),
      // BIO
      if (user.bio.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('PROFIL', primaryColor),
        pw.Text(user.bio, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800)),
        pw.SizedBox(height: 20),
      ],

      // EXP
      if (user.experiences.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('EXPÉRIENCE PROFESSIONNELLE', primaryColor),
        ...user.experiences.map((exp) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(exp.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Text(exp.period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(exp.organization, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                pw.Text(exp.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.4)),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 8),
      ],

      // EDU
      if (user.educations.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('FORMATION', primaryColor),
        ...user.educations.map((edu) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.Text(edu.period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 8),
      ],

      // COMPETENCES (en grille)
      if (user.skills.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('COMPÉTENCES', primaryColor),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.skills.map((s) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Text(s.name, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            );
          }).toList(),
        ),
        pw.SizedBox(height: 16),
      ],

      // PROJETS & RÉALISATIONS
      if (user.portfolioProjects.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('PROJETS & RÉALISATIONS', primaryColor),
        ...user.portfolioProjects.map((project) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(project.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(project.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.4)),
                if (project.technologies.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Technologies : ${project.technologies.join(", ")}', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: primaryColor)),
                ],
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 8),
      ],

      // CENTRES D'INTÉRÊT
      if (user.interests.isNotEmpty) ...[
        _buildMinimalisteSectionTitle('CENTRES D\'INTÉRÊT', primaryColor),
        pw.Text(user.interests.join(" • "), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        pw.SizedBox(height: 16),
      ],
    ];
  }

  // ---------------------------------------------------------
  // 3. HARVARD / CLASSIQUE (Optimisé ATS, très formel)
  // ---------------------------------------------------------
  static List<pw.Widget> buildHarvard(UserModel user, pw.MemoryImage? profileImage, String destination) {
    return [
      // HEADER (Tout centré)
      pw.Text(
        user.name.toUpperCase(),
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold()),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (user.city.isNotEmpty) pw.Text('${user.city}, ${user.country}', style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
          if (user.city.isNotEmpty && user.email.isNotEmpty) pw.Text(' | ', style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
          if (user.email.isNotEmpty) pw.Text(user.email, style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
          if (user.email.isNotEmpty && user.phone.isNotEmpty) pw.Text(' | ', style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
          if (user.phone.isNotEmpty) pw.Text(user.phone, style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Divider(color: PdfColors.black, thickness: 1),
      pw.SizedBox(height: 16),

      // EDUCATION
      if (user.educations.isNotEmpty) ...[
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('FORMATIONS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
        ),
        pw.SizedBox(height: 12),
        ...user.educations.map((edu) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu.institution, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
                      pw.Text(edu.title, style: pw.TextStyle(fontSize: 10, font: pw.Font.timesItalic())),
                    ],
                  ),
                ),
                pw.Text(edu.period, style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 12),
      ],

      // EXPERIENCE
      if (user.experiences.isNotEmpty) ...[
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('EXPÉRIENCES PROFESSIONNELLES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
        ),
        pw.SizedBox(height: 12),
        ...user.experiences.map((exp) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(exp.organization, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
                    ),
                    pw.Text(exp.period, style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
                  ],
                ),
                pw.Text(exp.title, style: pw.TextStyle(fontSize: 10, font: pw.Font.timesItalic())),
                if (exp.description.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('- ', style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
                      pw.Expanded(
                        child: pw.Text(exp.description, style: pw.TextStyle(fontSize: 10, font: pw.Font.times(), lineSpacing: 1.2)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 12),
      ],

      // PROJETS
      if (user.portfolioProjects.isNotEmpty) ...[
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('PROJETS & RÉALISATIONS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
        ),
        pw.SizedBox(height: 12),
        ...user.portfolioProjects.map((project) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(project.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
                    ),
                    if (project.technologies.isNotEmpty)
                      pw.Text(project.technologies.join(", "), style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, font: pw.Font.timesItalic())),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: pw.TextStyle(fontSize: 10, font: pw.Font.times())),
                    pw.Expanded(
                      child: pw.Text(project.description, style: pw.TextStyle(fontSize: 10, font: pw.Font.times(), lineSpacing: 1.2)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 12),
      ],

      // SKILLS
      if (user.skills.isNotEmpty || user.interests.isNotEmpty) ...[
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text('COMPÉTENCES & CENTRES D\'INTÉRÊT', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
        ),
        pw.SizedBox(height: 12),
        if (user.skills.isNotEmpty)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Compétences techniques : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
              pw.Expanded(
                child: pw.Text(
                  user.skills.map((s) => s.name).join(', '),
                  style: pw.TextStyle(fontSize: 10, font: pw.Font.times()),
                ),
              ),
            ],
          ),
        if (user.interests.isNotEmpty) ...[
          if (user.skills.isNotEmpty) pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Centres d\'intérêt : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: pw.Font.timesBold())),
              pw.Expanded(
                child: pw.Text(
                  user.interests.join(', '),
                  style: pw.TextStyle(fontSize: 10, font: pw.Font.times()),
                ),
              ),
            ],
          ),
        ],
      ],
    ];
  }
  // ---------------------------------------------------------
  // 4. EXÉCUTIF (Senior, Élégant, Timeline)
  // ---------------------------------------------------------
  static List<pw.Widget> buildExecutif(UserModel user, pw.MemoryImage? profileImage, PdfColor primaryColor, String destination) {
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  user.name.toUpperCase(),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black, letterSpacing: 1.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  user.professionalTitle.toUpperCase(),
                  style: pw.TextStyle(fontSize: 12, color: primaryColor, letterSpacing: 2),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  [
                    if (user.city.isNotEmpty) '${user.city}, ${user.country}',
                    if (user.phone.isNotEmpty) user.phone,
                    if (user.email.isNotEmpty) user.email,
                  ].join('  |  '),
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          if (profileImage != null && destination != 'international')
            pw.Container(
              width: 70,
              height: 70,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 24),
      pw.Divider(color: primaryColor, thickness: 1),
      pw.SizedBox(height: 24),

      if (user.bio.isNotEmpty) ...[
        pw.Text(
          'PROFIL EXÉCUTIF',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1),
        ),
        pw.SizedBox(height: 8),
        pw.Text(user.bio, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800)),
        pw.SizedBox(height: 24),
      ],

      if (user.experiences.isNotEmpty) ...[
        pw.Text(
          'PARCOURS PROFESSIONNEL',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1),
        ),
        pw.SizedBox(height: 16),
        ...user.experiences.map((exp) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 90,
                  child: pw.Text(
                    exp.period,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(exp.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(exp.organization, style: pw.TextStyle(fontSize: 10, color: primaryColor, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 6),
                      pw.Text(exp.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 8),
      ],

      if (user.educations.isNotEmpty) ...[
        pw.Text(
          'FORMATION',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1),
        ),
        pw.SizedBox(height: 16),
        ...user.educations.map((edu) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 90,
                  child: pw.Text(
                    edu.period,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(edu.institution, style: pw.TextStyle(fontSize: 9, color: primaryColor, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        pw.SizedBox(height: 8),
      ],

      if (user.skills.isNotEmpty || user.languages.isNotEmpty) ...[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (user.skills.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('COMPÉTENCES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    ...user.skills.map((s) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('• ${s.name}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    )).toList(),
                  ],
                ),
              ),
            if (user.languages.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LANGUES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1)),
                    pw.SizedBox(height: 12),
                    ...user.languages.map((l) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('• ${l.name} (${l.level}/5)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    )).toList(),
                  ],
                ),
              ),
          ],
        )
      ],
    ];
  }

  // ---------------------------------------------------------
  // 5. CRÉATIF (Bannière, 2 Colonnes dynamiques)
  // ---------------------------------------------------------
  static pw.PageTheme buildCreatifTheme(PdfColor primaryColor, UserModel user, pw.MemoryImage? profileImage, String destination) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(top: 140, left: 32, right: 32, bottom: 32),
      buildBackground: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  height: 120,
                  color: primaryColor,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: pw.Row(
                    children: [
                      if (profileImage != null && destination != 'international')
                        pw.Container(
                          width: 70,
                          height: 70,
                          margin: const pw.EdgeInsets.only(right: 20),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: PdfColors.white, width: 2),
                            image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              user.name.toUpperCase(),
                              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              user.professionalTitle,
                              style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              [
                                if (user.city.isNotEmpty) '${user.city}, ${user.country}',
                                if (user.phone.isNotEmpty) user.phone,
                                if (user.email.isNotEmpty) user.email,
                              ].join('  |  '),
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]
          )
        );
      }
    );
  }

  static List<pw.Widget> buildCreatifContent(UserModel user, PdfColor primaryColor) {
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Colonne Gauche (35%)
          pw.Expanded(
            flex: 35,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (user.skills.isNotEmpty) ...[
                  pw.Text('COMPÉTENCES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 30, height: 2, color: primaryColor),
                  pw.SizedBox(height: 12),
                  ...user.skills.map((s) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(s.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  )),
                  pw.SizedBox(height: 24),
                ],
                if (user.languages.isNotEmpty) ...[
                  pw.Text('LANGUES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 30, height: 2, color: primaryColor),
                  pw.SizedBox(height: 12),
                  ...user.languages.map((l) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text('${l.name} - ${l.level}/5', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  )),
                  pw.SizedBox(height: 24),
                ],
                if (user.interests.isNotEmpty) ...[
                  pw.Text('INTÉRÊTS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 4),
                  pw.Container(width: 30, height: 2, color: primaryColor),
                  pw.SizedBox(height: 12),
                  ...user.interests.map((i) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(i, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                  )),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          // Colonne Droite (65%)
          pw.Expanded(
            flex: 65,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (user.bio.isNotEmpty) ...[
                  pw.Text('PROFIL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 8),
                  pw.Text(user.bio, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800)),
                  pw.SizedBox(height: 24),
                ],
                if (user.experiences.isNotEmpty) ...[
                  pw.Text('EXPÉRIENCES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 16),
                  ...user.experiences.map((exp) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(exp.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(exp.organization, style: pw.TextStyle(fontSize: 10, color: primaryColor)),
                            pw.Text(exp.period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ]
                        ),
                        if (exp.description.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(exp.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800, lineSpacing: 1.4)),
                        ]
                      ],
                    ),
                  )),
                  pw.SizedBox(height: 8),
                ],
                if (user.educations.isNotEmpty) ...[
                  pw.Text('FORMATIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.SizedBox(height: 16),
                  ...user.educations.map((edu) => pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(edu.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(edu.institution, style: pw.TextStyle(fontSize: 9, color: primaryColor)),
                            pw.Text(edu.period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          ]
                        ),
                      ],
                    ),
                  )),
                ],
              ]
            )
          )
        ],
      )
    ];
  }

  // ---------------------------------------------------------
  // 6. TECH / START-UP (Épuré, Tags, Orienté Tech)
  // ---------------------------------------------------------
  static List<pw.Widget> buildTech(UserModel user, pw.MemoryImage? profileImage, PdfColor primaryColor, String destination) {
    return [
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  user.name,
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  user.professionalTitle,
                  style: pw.TextStyle(fontSize: 14, color: primaryColor, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  [
                    if (user.city.isNotEmpty) '${user.city}, ${user.country}',
                    if (user.phone.isNotEmpty) user.phone,
                    if (user.email.isNotEmpty) user.email,
                  ].join(' • '),
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                if (user.linkedin.isNotEmpty || user.github.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    [
                      if (user.linkedin.isNotEmpty) 'LinkedIn: ${user.linkedin}',
                      if (user.github.isNotEmpty) 'GitHub: ${user.github}',
                    ].join(' • '),
                    style: pw.TextStyle(fontSize: 9, color: primaryColor),
                  ),
                ]
              ],
            ),
          ),
          if (profileImage != null && destination != 'international')
            pw.Container(
              width: 60,
              height: 60,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.rectangle,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 24),
      
      // Skills en tags
      if (user.skills.isNotEmpty) ...[
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: user.skills.map((s) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Text(s.name, style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        pw.SizedBox(height: 24),
      ],

      if (user.bio.isNotEmpty) ...[
        pw.Text('À PROPOS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 8),
        pw.Text(user.bio, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5, color: PdfColors.grey800)),
        pw.SizedBox(height: 24),
      ],

      if (user.experiences.isNotEmpty) ...[
        pw.Text('EXPÉRIENCES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 12),
        ...user.experiences.map((exp) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(exp.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(exp.period, style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Text(exp.organization, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (exp.description.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(exp.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black, lineSpacing: 1.4)),
              ]
            ],
          ),
        )),
        pw.SizedBox(height: 8),
      ],

      if (user.portfolioProjects.isNotEmpty) ...[
        pw.Text('PROJETS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 12),
        ...user.portfolioProjects.map((proj) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(proj.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(proj.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              if (proj.technologies.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(proj.technologies.join(', '), style: pw.TextStyle(fontSize: 8, color: primaryColor)),
              ]
            ],
          ),
        )),
        pw.SizedBox(height: 8),
      ],

      if (user.educations.isNotEmpty) ...[
        pw.Text('FORMATIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        pw.SizedBox(height: 12),
        ...user.educations.map((edu) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(edu.title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(edu.institution, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Text(edu.period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        )),
      ],
    ];
  }

}
