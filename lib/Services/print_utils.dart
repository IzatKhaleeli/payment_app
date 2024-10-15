import '../Utils/Alignments.dart';

class PrintUtils {
  static List<int> initialization() {
    return [0x1B, 0x40];
  }
  static List<int> rasterMode() {
    return [0x1D, 0x76, 0x30, 0x00];
  }
  // Align Left
  static List<int> alignLeft() {
    return [0x1B, 0x61, 0x00];
  }

  // Align Center
  static List<int> alignCenter() {
    return [0x1B, 0x61, 0x01];
  }

  // Align Right
  static List<int> alignRight() {
    return [0x1B, 0x61, 0x02];
  }

  // Print bold text
  static List<int> boldText(String text) {
    List<int> bytes = [0x1B, 0x45, 0x01]; // Enable Bold
    bytes += text.codeUnits;
    bytes += [0x1B, 0x45, 0x00]; // Disable Bold
    return bytes;
  }

  // Utility method for printing any text with alignment
  static List<int> printAlignedText(String text, Alignments alignment) {
    List<int> bytes = [];
    if (alignment == Alignments.left) {
      bytes += alignLeft();
    } else if (alignment == Alignments.center) {
      bytes += alignCenter();
    } else if (alignment == Alignments.right) {
      bytes += alignRight();
    }
    bytes += text.codeUnits;
    return bytes;
  }

  // Print bold aligned text left
  static List<int> printBoldAlignedTextLeft(String text) {
    List<int> bytes = [];
    bytes += alignLeft();
    bytes += boldText(text);
    return bytes;
  }

  // Print bold aligned text center
  static List<int> printBoldAlignedTextCenter(String text) {
    List<int> bytes = [];
    bytes += alignCenter();
    bytes += boldText(text);
    return bytes;
  }

  // Print bold aligned text right
  static List<int> printBoldAlignedTextRight(String text) {
    List<int> bytes = [];
    bytes += alignRight();
    bytes += boldText(text);
    return bytes;
  }
}
