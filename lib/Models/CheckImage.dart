import 'dart:convert';
import 'dart:typed_data';

class CheckImage {
  int? id;
  int? paymentId;
  String fileName;
  String? mimeType;
  String base64Content;
  String? status;
  String? filePath;

  CheckImage({
    this.id,
    this.paymentId,
    required this.fileName,
    this.mimeType,
    required this.base64Content,
    this.status,
    this.filePath,
  });

  factory CheckImage.fromMap(Map<String, dynamic> map) {
    // Handle both String and Uint8List for base64Content
    var content = map['base64Content'];
    String base64Str;
    if (content is String) {
      base64Str = content;
    } else if (content is List<int>) {
      base64Str = base64.encode(content);
    } else if (content is Uint8List) {
      base64Str = base64.encode(content);
    } else {
      base64Str = '';
    }
    return CheckImage(
      id: map['id'],
      paymentId: map['paymentId'],
      fileName: map['fileName'] ?? '',
      mimeType: map['mimeType'],
      base64Content: base64Str,
      status: map['status'],
      filePath: map['filePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'fileName': fileName,
      'mimeType': mimeType,
      'base64Content': base64Content,
      'status': status,
      'filePath': filePath,
    };
  }

  @override
  String toString() {
    return 'CheckImage{id: $id, paymentId: $paymentId, fileName: $fileName, mimeType: $mimeType, base64Content: $base64Content, status: $status, filePath: $filePath}';
  }
}
