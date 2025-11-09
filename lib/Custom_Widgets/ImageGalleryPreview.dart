import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageGalleryPreview extends StatefulWidget {
  final List<Map<String, dynamic>> images; // expects base64Content and fileName
  final double thumbnailSize;

  ImageGalleryPreview({required this.images, this.thumbnailSize = 72});

  @override
  _ImageGalleryPreviewState createState() => _ImageGalleryPreviewState();
}

class _ImageGalleryPreviewState extends State<ImageGalleryPreview> {
  int _currentIndex = 0;
  bool _isFullscreen = false;

  List<Uint8List> get _bytesList => widget.images
      .map((m) => base64.decode(m['base64Content'] ?? ''))
      .where((b) => b.isNotEmpty)
      .toList();

  void _openFullscreen(int index) {
    setState(() {
      _currentIndex = index;
      _isFullscreen = true;
    });
  }

  void _closeFullscreen() {
    setState(() {
      _isFullscreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesList;
    if (bytes.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.thumbnailSize,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bytes.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openFullscreen(index),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(bytes[index],
                        width: widget.thumbnailSize,
                        height: widget.thumbnailSize,
                        fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isFullscreen) _buildFullscreen(context, bytes),
      ],
    );
  }

  Widget _buildFullscreen(BuildContext context, List<Uint8List> bytes) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: PageView.builder(
              controller: PageController(initialPage: _currentIndex),
              itemCount: bytes.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.memory(bytes[index], fit: BoxFit.contain),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: _closeFullscreen,
          ),
        ),
        Positioned(
          left: 8,
          top: MediaQuery.of(context).size.height / 2 - 28,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
            onPressed: () {
              if (_currentIndex > 0) setState(() => _currentIndex--);
            },
          ),
        ),
        Positioned(
          right: 8,
          top: MediaQuery.of(context).size.height / 2 - 28,
          child: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 28),
            onPressed: () {
              if (_currentIndex < bytes.length - 1)
                setState(() => _currentIndex++);
            },
          ),
        ),
      ],
    );
  }
}
