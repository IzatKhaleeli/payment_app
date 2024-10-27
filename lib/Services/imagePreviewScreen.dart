import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:ooredoo_app/Screens/printUI.dart';

import '../Screens/DashboardScreen.dart';
import 'bitmap.dart';

class ImagePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ImagePreviewScreen({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
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
      setState(() {
        _resizedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Arrow back icon
          onPressed: () {
            // Navigate to the Dashboard screen
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => PrintPage()),
            // );
            },
        ),
      ),
      body: _resizedImage != null
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
