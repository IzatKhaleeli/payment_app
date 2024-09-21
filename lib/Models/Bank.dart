import 'dart:convert';

class Bank {
  final String id;
  final String? arabicName;
  final String? englishName;

  Bank({
    required this.id,
    this.arabicName,
    this.englishName,
  });

  static String decodeArabicString(String encodedString) {
    // Convert the encoded string to a list of bytes
    List<int> bytes = encodedString.codeUnits;

    // Decode the bytes to a proper UTF-8 string
    String decodedString = utf8.decode(bytes);

    return decodedString;
  }

  factory Bank.fromMapArabic(Map<String, dynamic> json) {
    return Bank(
      id: json['code'] as String,
      arabicName: decodeArabicString(json['extValue1'].toString()),
      englishName: json['dispalyValue'] as String?,
    );
  }

  factory Bank.fromMap(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      arabicName: json['arabicName'],
      englishName: json['englishName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arabicName': arabicName,
      'englishName': englishName,
    };
  }

  @override
  String toString() {
    return 'Bank{id: $id, arabicName: $arabicName, englishName: $englishName}';
  }
}
