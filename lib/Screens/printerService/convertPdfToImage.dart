import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as img; // Import the image package for img.Image
import 'dart:typed_data';

class PdfConverter {
  // Convert the PDF to an img.Image (from the 'image' package) for printing
  static Future<img.Image> convertPdfToImage(String pdfPath) async {
    print("convertPdfToImage method started");
    // Open the PDF document
    try {
    final document = await PdfDocument.openFile(pdfPath);

    // Get the first page of the PDF
    final page = await document.getPage(1);  //  pageNumber = 1
    print("page is one");

    // Render the page as an image
    final pdfPageImage = await page.render(
      width: 300, // Image width (adjust as needed)
      height: 400, // Image height (adjust as needed)
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
      format: img.Format.rgba, // The format must match the pixel format
    );
    print("pixels is created");

    // Clean up resources
    document.dispose();

    return image; // Return the img.Image for further processing
    } catch (e) {
      print("Error converting PDF to image: $e");
      rethrow;  // Rethrow the error for further handling if needed
    }
  }

}
