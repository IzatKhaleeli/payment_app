class CheckImage {
  int? id;
  int? paymentId;
  String fileName;
  String? mimeType;
  String base64Content; // store base64 representation

  CheckImage({
    this.id,
    this.paymentId,
    required this.fileName,
    this.mimeType,
    required this.base64Content,
  });

  factory CheckImage.fromMap(Map<String, dynamic> map) {
    return CheckImage(
      id: map['id'],
      paymentId: map['paymentId'],
      fileName: map['fileName'] ?? '',
      mimeType: map['mimeType'],
      base64Content: map['base64Content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'fileName': fileName,
      'mimeType': mimeType,
      'base64Content': base64Content,
    };
  }
}
