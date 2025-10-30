import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../Services/LocalizationService.dart';
import '../../../core/constants.dart';

class UploadFileWidget extends StatefulWidget {
  final double scale;
  final String label;
  final Function(List<File>) onFilesSelected;
  final List<File>? fileToShow;

  const UploadFileWidget({
    Key? key,
    required this.scale,
    required this.label,
    required this.onFilesSelected,
    this.fileToShow,
  }) : super(key: key);

  @override
  State<UploadFileWidget> createState() => _UploadFileWidgetState();
}

class _UploadFileWidgetState extends State<UploadFileWidget> {
  List<File> selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _containerKey = GlobalKey();

  Future<void> _pickFile() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        final newFiles = images.map((e) => File(e.path)).toList();
        setState(() {
          selectedFiles.addAll(newFiles);
        });
        widget.onFilesSelected(selectedFiles);
      }
    } catch (e) {
      print("Gallery pick error: $e");
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          // insert at start
          selectedFiles.insert(0, File(photo.path));
        });
        widget.onFilesSelected(selectedFiles);
      }
    } catch (e) {
      print("Camera capture error: $e");
    }
  }

  void clearFile() {
    setState(() {
      selectedFiles.clear();
    });
  }

  @override
  void didUpdateWidget(covariant UploadFileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // update when parent provides files
    final incoming = widget.fileToShow ?? [];
    if (!listEquals(incoming, selectedFiles)) {
      setState(() {
        selectedFiles = List.from(incoming);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization =
        Provider.of<LocalizationService>(context, listen: false);
    final labelFontSize = (12.0 * widget.scale).clamp(12.0, 14.0);

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: labelFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            key: _containerKey,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              offset: _calculateCenterOffset(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'upload',
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      appLocalization.getLocalizedString("uploadFromGallery"),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const CustomDividerMenuItem(height: 1),
                PopupMenuItem<String>(
                  value: 'camera',
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      appLocalization.getLocalizedString("takePhoto"),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'upload') {
                  _pickFile();
                } else if (value == 'camera') {
                  _captureFromCamera();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload,
                    color: AppColors.primaryRed,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  // show thumbnails and count
                  if (selectedFiles.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        itemCount: selectedFiles.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final f = selectedFiles[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  f,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    icon: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedFiles.removeAt(index);
                                      });
                                      widget.onFilesSelected(selectedFiles);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Text(
                      appLocalization.getLocalizedString("uploadFile"),
                      style: TextStyle(
                        fontSize: 13 * widget.scale,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _calculateCenterOffset() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      return Offset(size.width / 2, 0);
    }
    return Offset.zero;
  }
}

class CustomDividerMenuItem extends PopupMenuEntry<String> {
  final double height;

  const CustomDividerMenuItem({this.height = 1});

  @override
  bool represents(String? value) => false;

  @override
  State<CustomDividerMenuItem> createState() => _CustomDividerMenuItemState();
}

class _CustomDividerMenuItemState extends State<CustomDividerMenuItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Divider(
        color: Colors.grey,
        height: widget.height,
        thickness: 1,
        indent: 8,
        endIndent: 8,
      ),
    );
  }
}
