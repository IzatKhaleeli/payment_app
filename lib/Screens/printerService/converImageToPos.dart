import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ConvertImageToPos {
  /// Static method to decode an image from assets.
  static Future<img.Image> loadImageFromAssets(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    Uint8List bytes = data.buffer.asUint8List();
    return img.decodeImage(bytes)!;
  }

  /// Static method to prepare an image for printing by resizing it and
  static Future<List<int>> prepareImageForPrint(
      img.Image image, CapabilityProfile profile) async {
    final generator = Generator(PaperSize.mm80, profile);

    // Resize image to fit the paper width.
    img.Image resized = img.copyResize(image, width: 575);
    List<int> commands = [];
    commands += generator.imageRaster(resized, align: PosAlign.center);
    commands += generator.feed(3);

    return commands;
  }
}
