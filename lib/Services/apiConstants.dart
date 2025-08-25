// 'http://192.168.20.65:8080';  //local
// 'http://172.20.0.160:8080';   //ooredoo testing
// 'https://b2bpayments.ooredoo.ps'; //ooredoo production
const String baseUrl = 'http://172.20.0.160:8080';
//
const String apiUrlLOV = '$baseUrl/ApplicationUtils/getLOVList?listname=';
const String apiUrlLogin = '$baseUrl/authentication-server/mobile/login';
const String apiUrlLogout = '$baseUrl/api/v1/validation/logout';
const String apiUrl = '$baseUrl/payments/sync';
const String apiUrlCancel = '$baseUrl/payments/cancel';
const String apiUrlDeleteExpired = '$baseUrl/ApplicationUtils/getDisplay?listname=CONFIGURATION&code=ARCHIVING_DURATION_IN_DAYS';
const String apiUrlSMS = '$baseUrl/sms/send';
const String apiUrlEmail = '$baseUrl/email/send';
