import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'imagePreviewScreen.dart';

class ImageToEscPosConverter {
  // Load image from assets
  static Future<img.Image?> loadImageFromAssets(String path) async {
    try {
      ByteData byteData = await rootBundle.load(path);
      final imageBytes = byteData.buffer.asUint8List(); // Convert to Uint8List
      return img.decodeImage(imageBytes); // Decode the image
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  // Convert the image to ESC/POS format
  static Uint8List convertImageToEscPosCommands(context,img.Image image, int maxWidth) {
    // Resize the image to the printer's width (if necessary)
    if (image.width > maxWidth) {
      image = img.copyResize(image, width: maxWidth);
    }
    print("Resized image dimensions: width: ${image.width}, height: ${image.height}");
    // Convert the image to grayscale

    //image = img.grayscale(image);
    image = img.bitmapToGray(image);
    print("Converted to grayscale: width: ${image.width}, height: ${image.height}");


    // image = convertGreyImgByFloyd(image);
    // print("image dim :width :${image.width}, hieght :${image.height}");

    showImagePreview(context,image,320);
    print("test");
    // Create ESC/POS commands
    return generateEscPosCommand(image);
  }


  /// Convert the image to grayscale using Floyd-Steinberg dithering
  static img.Image convertGreyImgByFloyd(img.Image source) {
    int width = source.width;
    int height = source.height;

    // Create an array for pixel data and luminance values
    List<int> pixels = source.getBytes();
    List<int> luminance = List<int>.filled(width * height, 0);

    // Extract the red channel for dithering (you can also average R, G, B for better grayscale)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int pixel = pixels[(y * width + x) * 4]; // RGBA format
        int red = (pixel >> 16) & 0xFF;           // Extract red channel
        luminance[y * width + x] = red;          // Store luminance
      }
    }

    // Apply Floyd-Steinberg dithering
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int oldPixel = luminance[y * width + x];
        int newPixel = (oldPixel >= 176) ? 255 : 0; // Thresholding
        int quantError = oldPixel - newPixel;

        // Set the dithered pixel to black or white
        int color = (newPixel == 255) ? 0xFFFFFFFF : 0xFF000000; // White or Black
        pixels[(y * width + x) * 4] = color; // Set RGBA pixel

        // Spread the quantization error to neighboring pixels
        if (x + 1 < width) luminance[y * width + (x + 1)] += (quantError * 7) ~/ 16;
        if (y + 1 < height) {
          if (x > 0) luminance[(y + 1) * width + (x - 1)] += (quantError * 3) ~/ 16;
          luminance[(y + 1) * width + x] += (quantError * 5) ~/ 16;
          if (x + 1 < width) luminance[(y + 1) * width + (x + 1)] += quantError ~/ 16;
        }
      }
    }

    // Create and return a new image from the modified pixels
    img.Image resultImage = img.Image.fromBytes(width, height, pixels, format: img.Format.rgba);
    return resultImage;
  }

  // Generate ESC/POS command for the printer

  static Uint8List generateEscPosCommand(img.Image image) {
    final width = image.width;
    final height = image.height;

    // Calculate the number of bytes needed per row (8 pixels per byte)
    int bytesPerRow = (width + 7) ~/ 8; // (width / 8) rounded up

    // ESC * command (select bit image mode)
    final List<int> escPosHeader = [
      0x1D, 0x76, 0x30, 0x00, // Select bit image mode
      bytesPerRow % 256, bytesPerRow ~/ 256, // Width in bytes
      height % 256, height ~/ 256, // Height
    ];

    // Convert image data to binary format for the printer
    final List<int> imageData = [];

    for (var y = 0; y < height; ++y) {
      for (var x = 0; x < bytesPerRow; ++x) {
        int byte = 0;
        int var19 = x * 8; // Calculate the bit position for 8 pixels

        for (var bit = 0; bit < 8; ++bit) {
          if (var19 + bit < width) { // Ensure we don't go out of bounds
            final pixel = image.getPixel(var19 + bit, y); // Get pixel color
            final luminance = img.getLuminance(pixel); // Get grayscale value

            if (luminance < 128) { // Black pixel condition
              byte |= (1 << (7 - bit)); // Set the bit for black pixels (MSB to LSB)
            }
          }
        }

        imageData.add(byte); // Add the constructed byte to the image data
      }
    }

    // Combine header and image data
    return Uint8List.fromList([...escPosHeader, ...imageData]);
  }

  // Load the image from assets and show the preview
  static void showImagePreview(BuildContext context, img.Image image, int maxWidth) async {
    if (image != null) {
      image = img.copyResize(image, width: maxWidth); // Resize the image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imageBytes: Uint8List.fromList(img.encodePng(image!))),
        ),
      );
    }
  }

}
