import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class PdfConverter {
  // Convert the PDF to an img.Image (from the 'image' package) for printing with higher resolution
  static Future<img.Image> convertPdfToImage(String pdfPath) async {
    print("convertPdfToImage method started");
    try {
      final document = await PdfDocument.openFile(pdfPath);

      // Get the first page of the PDF
      final page = await document.getPage(1);  // pageNumber = 1
      print("page is one");

      // Set higher resolution (DPI - dots per inch)
      final dpi = 352;  // Set the DPI you need (higher DPI = better quality)
      final width = dpi * page.width / 72; // 72 is the default PDF DPI
      final height = dpi * page.height / 72;

      // Render the page as an image
      final pdfPageImage = await page.render(
        width: width.toInt(),
        height: height.toInt(),
        x: 0,
        y: 0,
      );
      print("pdfPageImage is created");

      // Convert the rendered image pixels to img.Image (from Uint8List)
      final pixels = pdfPageImage.pixels;
      img.Image image = img.Image.fromBytes(
        pdfPageImage.width,
        pdfPageImage.height,
        Uint8List.fromList(pixels),
        format: img.Format.rgba, // Ensure format matches the pixel data
      );
      print("pixels are created");

      // Clean up resources
      document.dispose();

      return image; // Return the img.Image for further processing
    } catch (e) {
      print("Error converting PDF to image: $e");
      rethrow;  // Rethrow the error for further handling if needed
    }
  }
}