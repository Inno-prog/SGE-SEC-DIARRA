import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// Shows an uploaded PDF inline with visible, readable pages.
/// Uses `PdfPreview` from the `printing` package, which rasterizes each page
/// and renders it as an image — the content is visible without downloading.
class PdfViewerScreen extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat format) onBuild;
  final String title;

  const PdfViewerScreen({super.key, required this.onBuild, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => await onBuild(format),
                name: title,
              );
            },
            tooltip: 'Imprimer',
          ),
        ],
      ),
      body: PdfPreview(
        build: onBuild,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        useActions: false,
        pdfFileName: title,
        onError: (context, error) {
          showSnack(context, 'Erreur: $error', isError: true);
          return const Center(child: Text('Erreur de chargement'));
        },
      ),
    );
  }
}