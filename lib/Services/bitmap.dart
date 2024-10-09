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
      List<int> bytes = byteData.buffer.asUint8List();

      return img.decodeImage(bytes); // Decode the image
    } catch (e) {
      print('Failed to decode image.: $e');
      return null;
    }
  }

  // Convert the image to ESC/POS format
  static Future<Uint8List> convertImageToEscPosCommands(context,img.Image image, int maxWidth) async {
    print("convertImageToEscPosCommands started");

    // Step 1: Resize the image to the printer's width (if necessary)
    int newHeight = (image.height * maxWidth / image.width).toInt();
    img.Image resizedImage = img.copyResize(image, width: maxWidth, height: newHeight);
    print("Resized image dimensions: width: ${resizedImage.width}, height: ${resizedImage.height}");

    // Step 2: Convert to grayscale
    img.Image grayscaleImage = bitmap2Gray(resizedImage);
    print("grayscaleImage image dimensions: width: ${grayscaleImage.width}, height: ${grayscaleImage.height}");

    // Step 3: Apply Floyd-Steinberg dithering to the grayscale image
   img.Image ditheredImage = await convertGreyImgByFloyed(grayscaleImage);

    //Preview the dithered image
    showImagePreview(context, ditheredImage); // Pass ditheredImage instead of grayscaleImage

    // Step 4: Convert the dithered image to ESC/POS commands
    return imageToEscPosCommands(ditheredImage);
  }

  /// Convert a color image to grayscale in Flutter (similar to Java's bitmap2Gray)
  static img.Image bitmap2Gray(img.Image src) {
    // Create a new grayscale image with the same width and height
    img.Image grayImage = img.Image(src.width, src.height);

    // Iterate through each pixel in the source image
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        // Get the current pixel's color
        int pixel = src.getPixel(x, y);
        int r = img.getRed(pixel);
        int g = img.getGreen(pixel);
        int b = img.getBlue(pixel);

        // Convert the color to grayscale using luminance formula
        int gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();

        // Set the new grayscale pixel
        grayImage.setPixel(x, y, img.getColor(gray, gray, gray));
      }
    }


    return grayImage; // Return the grayscale image
  }

  static Future<img.Image> convertGreyImgByFloyed(img.Image grayscaleImage) async {
    // Ensure that the input image is already in grayscale.
    int width = grayscaleImage.width;
    int height = grayscaleImage.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int oldPixel = grayscaleImage.getPixel(x, y) & 0xFF;  // Grayscale value
        int newPixel = oldPixel < 128 ? 0 : 255;  // Threshold to black or white
        int error = oldPixel - newPixel;

        // Set the new pixel color (black or white)
        grayscaleImage.setPixel(x, y, img.getColor(newPixel, newPixel, newPixel));

        // Distribute the error to neighboring pixels using Floyd-Steinberg coefficients
        if (x + 1 < width) {
          int rightPixel = grayscaleImage.getPixel(x + 1, y) & 0xFF;
          grayscaleImage.setPixel(x + 1, y, _applyError(rightPixel, error, 7 / 16));
        }
        if (x - 1 >= 0 && y + 1 < height) {
          int bottomLeftPixel = grayscaleImage.getPixel(x - 1, y + 1) & 0xFF;
          grayscaleImage.setPixel(x - 1, y + 1, _applyError(bottomLeftPixel, error, 3 / 16));
        }
        if (y + 1 < height) {
          int bottomPixel = grayscaleImage.getPixel(x, y + 1) & 0xFF;
          grayscaleImage.setPixel(x, y + 1, _applyError(bottomPixel, error, 5 / 16));
        }
        if (x + 1 < width && y + 1 < height) {
          int bottomRightPixel = grayscaleImage.getPixel(x + 1, y + 1) & 0xFF;
          grayscaleImage.setPixel(x + 1, y + 1, _applyError(bottomRightPixel, error, 1 / 16));
        }
      }
    }

    return grayscaleImage;
  }

// Helper function to apply the error diffusion to the pixel value
  static int _applyError(int pixel, int error, double factor) {
    int newPixelValue = (pixel + error * factor).clamp(0, 255).toInt();
    return img.getColor(newPixelValue, newPixelValue, newPixelValue);  // Grayscale
  }


  /// Convert a bitmap2Gray image to ESCPOS image in Flutter (similar to Java's bitmap2Gray)
  static Uint8List imageToEscPosCommands(img.Image image) {
    List<int> bytes = [];

    // Initialize the printer to raster mode
    bytes += [0x1B, 0x40]; // ESC @ - Initialize the printer
    bytes += [0x1D, 0x76, 0x30, 0x00]; // ESC * Raster mode command

    int width = image.width;
    int height = image.height;

    // Set the width in bytes, rounded up to the nearest byte boundary
    int widthBytes = ((width + 7) ~/ 8);
    bytes += [(widthBytes % 256), (widthBytes ~/ 256)]; // Width of the image in bytes
    bytes += [(height % 256), (height ~/ 256)]; // Height of the image in pixels

    // Loop through the image's pixels and convert to monochrome (0 or 1 bit)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x += 8) {
        int byte = 0;

        // Create a byte by setting 8 pixels at a time
        for (int bit = 0; bit < 8; bit++) {
          if (x + bit < width) {
            int pixel = image.getPixel(x + bit, y) & 0xFF;
            if (pixel == 0x00) { // Assuming the dithered image uses 0 for black and 255 for white
              byte |= (1 << (7 - bit)); // Set the bit if it's black
            }
          }
        }
        bytes.add(byte); // Add this byte to the ESC/POS command buffer
      }
    }

    // Add final feed and cut commands if required
    bytes += [0x0C]; // Form feed (optional)
    bytes += [0x1B, 0x69]; // ESC i - Full cut (optional)

    return Uint8List.fromList(bytes);
  }

  // Load the image from assets and show the preview
  static void showImagePreview(BuildContext context, img.Image? image) async {
    if (image != null) {
      Uint8List imageBytes = Uint8List.fromList(img.encodePng(image));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imageBytes: imageBytes),
        ),
      );
    } else {
      print("Image is null. Cannot preview.");
    }
  }


}
