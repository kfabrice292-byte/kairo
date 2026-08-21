import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/models/user_model.dart';

import '../../core/utils/payment_utils.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class PdfPreviewScreen extends StatefulWidget {
  final UserModel user;
  final Future<Uint8List> Function() generatePdf;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.user,
    required this.generatePdf,
    this.title = 'Aperçu du Document',
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isPaying = false;
  Uint8List? _pdfData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) async {
                _pdfData ??= await widget.generatePdf();
                return _pdfData!;
              },
              allowPrinting: widget.user.isPremium,
              allowSharing: widget.user.isPremium,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: 'CV de ${widget.user.name}.pdf',
              onPrinted: _handleDownload,
              onShared: _handleDownload,
            ),
          ),
          if (!widget.user.isPremium)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isPaying ? null : () => _processPaymentAndExport(context),
                    icon: _isPaying 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download, color: Colors.white),
                    label: Text(
                      _isPaying ? 'Redirection...' : 'Télécharger / Exporter (350 FCFA)',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDownload(BuildContext context) {
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document exporté avec succès !')),
     );
  }

  Future<void> _processPaymentAndExport(BuildContext context) async {
    PaymentUtils.checkAndConsumeCredit(
      context,
      documentName: widget.title,
      onGranted: () async {
        if (_pdfData != null) {
          await Printing.sharePdf(bytes: _pdfData!, filename: 'KAIRO_Document.pdf');
        }
      },
    );
  }
}
