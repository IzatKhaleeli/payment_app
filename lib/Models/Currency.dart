import 'dart:convert';

class Currency {
  final String id;
  final String? arabicName;
  final String? englishName;

  Currency({
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


  factory Currency.fromMap(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] ?? '', // Default to empty string if null
      arabicName: json['arabicName']?? null,
      englishName: json['englishName'] ?? '', // Default to empty string if null
    );
  }

  factory Currency.fromMapArabic(Map<String, dynamic> json) {
    return Currency(
      id: json['code'] as String,
      arabicName: decodeArabicString(json['extValue1'].toString()),
      englishName: json['dispalyValue'] as String?,
    );
  }

  // Convert an instance to a JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  // Create an instance from a JSON string
  factory Currency.fromJson(String source) {
    return Currency.fromMap(jsonDecode(source));
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
    return 'Currency{id: $id, arabicName: $arabicName, englishName: $englishName}';
  }
}
