import 'dart:typed_data';
import 'package:flutter/material.dart';

Future<void> showImageGalleryPreview({
  required BuildContext context,
  required List<Uint8List> images,
  String invalidImageMessage = 'Invalid image',
}) async {
  if (images.isEmpty) return;

  int currentIndex = 0;
  final pageController = PageController(initialPage: currentIndex);

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black.withOpacity(0.9),
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.length,
                controller: pageController,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (context, index) {
                  final bytes = images[index];
                  if (bytes.isEmpty) {
                    return Center(
                      child: Text(invalidImageMessage,
                          style: TextStyle(color: Colors.white)),
                    );
                  }
                  return InteractiveViewer(
                    child: Center(
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  );
                },
              ),
              Positioned(
                left: 8,
                top: 28,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (images.length > 1) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        if (currentIndex > 0) {
                          pageController.previousPage(
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onPressed: () {
                        if (currentIndex < images.length - 1) {
                          pageController.nextPage(
                              duration: Duration(milliseconds: 250),
                              curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      });
    },
  );
}
