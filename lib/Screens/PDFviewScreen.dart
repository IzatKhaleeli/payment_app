import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';

import '../Services/LocalizationService.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String filePath;

  PdfPreviewScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString("pdfPreview")),
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
        onRender: (pages) {
          print("Document rendered with $pages pages");
        },
        onError: (error) {
          print(error.toString());
        },
      ),
    );
  }
}
