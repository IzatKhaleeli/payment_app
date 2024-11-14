import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageView extends StatelessWidget {
  final img.Image image; // Accept img.Image instead of pdfPath

  // Constructor that takes the img.Image
  ImageView({required this.image});

  @override
  Widget build(BuildContext context) {
    // Encode the img.Image to PNG format
    Uint8List imageBytes = Uint8List.fromList(img.encodePng(image));

    return Scaffold(
      appBar: AppBar(
        title: Text("Image View"),
      ),
      body: Center(
        child: Image.memory(
          imageBytes, // Pass the PNG-encoded byte array
          width: 300, // Display width (adjust as needed)
          height: 400, // Display height (adjust as needed)
          fit: BoxFit.contain, // Scale the image to fit
        ),
      ),
    );
  }
}
