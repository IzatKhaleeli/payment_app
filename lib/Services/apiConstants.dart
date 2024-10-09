// const String apiUrlLogin = 'http://192.168.20.65:8080/authentication-server/mobile/login';
// const String apiUrl = 'http://192.168.20.65:8080/payments/sync';
// const String apiUrlCancel='http://192.168.20.65:8080/payments/cancel';
// const String apiUrlDeleteExpired='http://192.168.20.65:8080/ApplicationUtils/getDisplay?listname=CONFIGURATION&code=ARCHIVING_DURATION_IN_DAYS';
// const String apiUrlSMS='http://192.168.20.65:8080/send/sms';
// const String apiUrlEmail='http://192.168.20.65:8080/send/email';
// const String apiUrlLOV='192.168.20.65:8080/ApplicationUtils/getLOVList?listname=';

const String apiUrlLOV='http://172.20.0.160:8080/ApplicationUtils/getLOVList?listname=';
const String apiUrlLogin = 'http://172.20.0.160:8080/authentication-server/mobile/login';
const String apiUrlLogout = 'http://172.20.0.160:8080/api/v1/validation/logout';
const String apiUrl = 'http://172.20.0.160:8080/payments/sync';
const String apiUrlCancel='http://172.20.0.160:8080/payments/cancel';
const String apiUrlDeleteExpired='http://172.20.0.160:8080/ApplicationUtils/getDisplay?listname=CONFIGURATION&code=ARCHIVING_DURATION_IN_DAYS';
const String apiUrlSMS='http://172.20.0.160:8080/sms/send';
const String apiUrlEmail='http://172.20.0.160:8080/email/send';


//
// /// Convert a bitmap2Gray image to ESCPOS image in Flutter (similar to Java's bitmap2Gray)
// static Uint8List imageToEscPosCommands(img.Image image) {
// // Calculate width in bytes
// int width = (image.width + 7) ~/ 8;
// List<int> bytes = [];
//
// for (int y = 0; y < image.height; y++) {
// for (int x = 0; x < width * 8; x += 8) {
// int byte = 0x00;
// for (int bit = 0; bit < 8; bit++) {
// if ((x + bit) < image.width) {
// // Get luminance and check if it's below threshold
// if (img.getLuminance(image.getPixel(x + bit, y)) < 128) {
// byte |= (0x80 >> bit); // Set the bit for black pixel
// }
// }
// }
// bytes.add(byte); // Append the byte for this section
// }
// }
//
// // ESC * m nL nH bitmapData
// // Prepare ESC/POS command header
// List<int> header = [
// 0x1B,  // ESC
// 0x2A,  // *
// 0x00,  // m (0 for dot density)
// width & 0xFF,  // nL (low byte of width)
// (width >> 8) & 0xFF,  // nH (high byte of width)
// ];
//
// List<int> fullCommand = header + bytes;
//
// // Debug output - optional
// print('ESC/POS Command: ${fullCommand.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
//
// return Uint8List.fromList(fullCommand);
// }





// static Uint8List imageToEscPosCommands(img.Image image) {
// // Calculate width in bytes
// int width = (image.width + 7) ~/ 8;
// List<int> bytes = [];
//
// for (int y = 0; y < image.height; y++) {
// for (int x = 0; x < width * 8; x += 8) {
// int byte = 0x00;
// for (int bit = 0; bit < 8; bit++) {
// if ((x + bit) < image.width) {
// if (img.getLuminance(image.getPixel(x + bit, y)) < 128) {
// byte |= (0x80 >> bit);
// }
// }
// }
// bytes.add(byte);
// }
// }
//
// // ESC * m nL nH bitmapData
// // Prepare ESC/POS command header
// List<int> header = [
// 0x1B, 0x2A, 0x00,  // ESC * m
// width & 0xFF,      // nL
// (width >> 8) & 0xFF  // nH
// ];
//
// return Uint8List.fromList(header + bytes);
// }
