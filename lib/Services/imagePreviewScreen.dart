import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'bitmap.dart';

class ImagePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final int maxWidth;

  const ImagePreviewScreen({
    Key? key,
    required this.imageBytes,
    this.maxWidth = 320, // Default maxWidth for resizing
  }) : super(key: key);

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  Uint8List? _resizedImageBytes;
  img.Image? _resizedImage;

  @override
  void initState() {
    super.initState();
    _loadAndProcessImage();
  }

  Future<void> _loadAndProcessImage() async {
    // Decode the image from bytes
    img.Image? image = img.decodeImage(widget.imageBytes);

    if (image != null) {
      // Resize the image
      Uint8List escPosCommands = ImageToEscPosConverter.convertImageToEscPosCommands(context,image, widget.maxWidth);

      setState(() {
        _resizedImageBytes = escPosCommands;
        _resizedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
      ),
      body: _resizedImageBytes != null && _resizedImage != null
          ? Column(
        children: [
          // Show the resized image
          Image.memory(Uint8List.fromList(img.encodePng(_resizedImage!))),
          const SizedBox(height: 20),
          const Text('Resized Image Preview'),
        ],
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
