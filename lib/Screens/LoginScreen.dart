import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../Custom_Widgets/CustomButton.dart';
import '../Custom_Widgets/CustomTextField.dart';
import '../Custom_Widgets/LogoWidget.dart';
import '../Models/LoginState.dart';
import '../Services/LOV_Sync.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import '../Services/secure_storage.dart';
import '../core/constants.dart';
import 'DashboardScreen.dart';
import 'dart:async';

class LoginScreen extends StatelessWidget {
  static const List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'العربية', 'code': 'ar'},
  ];
  const LoginScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690), minTextAdapt: true);
    double maxWidth =
        ScreenUtil().screenWidth > 600 ? 600.w : ScreenUtil().screenWidth * 0.9;
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

    final screenSize = MediaQuery.of(context).size;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationService>(
          create: (_) {
            var localizationState = LocalizationService();
            localizationState.initLocalization();
            return localizationState;
          },
        ),
        ChangeNotifierProvider<LoginState>(
          create: (_) => LoginState(),
        ),
      ],
      child: Consumer2<LocalizationService, LoginState>(
        builder: (context, localizationService, loginState, _) {
          return Directionality(
            textDirection: localizationService.selectedLanguageCode == "ar"
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Color(0xFFF7F7F7),
                elevation: 0,
                actions: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildLanguageDropdown(
                            scale, context, localizationService),
                      ],
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: screenSize.width * 0.05,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const LogoWidget(),
                            const SizedBox(height: 32),
                            CustomTextField(
                              hint: localizationService.isLocalizationLoaded
                                  ? localizationService
                                      .getLocalizedString('userName')
                                  : 'Username',
                              icon: Icons.person_outline,
                              onChanged: loginState.setUsername,
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              hint: localizationService.isLocalizationLoaded
                                  ? localizationService
                                      .getLocalizedString('password')
                                  : 'Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              onChanged: loginState.setPassword,
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: localizationService
                                            .isLocalizationLoaded
                                        ? localizationService
                                            .getLocalizedString('login')
                                        : 'Login', // Fallback if localization is not loaded
                                    onPressed: () async {
                                      var connectivityResult =
                                          await (Connectivity()
                                              .checkConnectivity());
                                      if (connectivityResult.toString() ==
                                          '[ConnectivityResult.none]') {
                                        _showLoginFailedDialog(
                                            scale,
                                            context,
                                            localizationService
                                                .getLocalizedString(
                                                    'noInternet'),
                                            localizationService
                                                    .isLocalizationLoaded
                                                ? localizationService
                                                    .getLocalizedString(
                                                        'noInternetConnection')
                                                : 'No Internet Connection',
                                            localizationService
                                                .selectedLanguageCode,
                                            localizationService);
                                      } else {
                                        bool isValid =
                                            validateLoginInputs(loginState);
                                        if (isValid) {
                                          _handleLogin(scale, context,
                                              localizationService);
                                          var loginResult =
                                              await loginState.login(
                                                  loginState.username,
                                                  loginState.password);
                                          if (loginResult["status"] == 200) {
                                            var versionChecker =
                                                await PaymentService
                                                    .getMinVersion();
                                            if (versionChecker == false) {
                                              print("App update required");
                                              Navigator.of(context).pop();
                                              _showLoginFailedDialog(
                                                  scale,
                                                  context,
                                                  localizationService
                                                      .getLocalizedString(
                                                          'updateAppBody'),
                                                  localizationService
                                                          .isLocalizationLoaded
                                                      ? localizationService
                                                          .getLocalizedString(
                                                              'updateAppTitle')
                                                      : 'Update Required',
                                                  localizationService
                                                      .selectedLanguageCode,
                                                  localizationService);
                                              return;
                                            } else {
                                              print("App is up-to-date.");

                                              await saveCredentials(
                                                loginState.username,
                                                loginState.password,
                                              );
                                              await LOVCompareService
                                                  .compareAndSyncCurrencies();
                                              await LOVCompareService
                                                  .compareAndSyncBanks();
                                              await PaymentService
                                                  .getExpiredPaymentsNumber();
                                              Navigator.of(context).pop();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        DashboardScreen()),
                                              );
                                            }
                                          } else if (loginResult['status'] ==
                                              408) {
                                            Navigator.of(context).pop();
                                            _showLoginFailedDialog(
                                                scale,
                                                context,
                                                localizationService
                                                    .getLocalizedString(
                                                        'loginFailedTimeout'),
                                                localizationService
                                                        .isLocalizationLoaded
                                                    ? localizationService
                                                        .getLocalizedString(
                                                            'loginfailed')
                                                    : 'Login Failed',
                                                localizationService
                                                    .selectedLanguageCode,
                                                localizationService);
                                          } else if (loginResult['status'] ==
                                              401) {
                                            Navigator.of(context).pop();

                                            _showLoginFailedDialog(
                                                scale,
                                                context,
                                                localizationService
                                                    .getLocalizedString(
                                                        'loginFailedwrong'),
                                                localizationService
                                                        .isLocalizationLoaded
                                                    ? localizationService
                                                        .getLocalizedString(
                                                            'loginfailed')
                                                    : 'Login Failed',
                                                localizationService
                                                    .selectedLanguageCode,
                                                localizationService);
                                          } else if (loginResult['status'] ==
                                              503) {
                                            Navigator.of(context).pop();

                                            _showLoginFailedDialog(
                                                scale,
                                                context,
                                                localizationService
                                                    .getLocalizedString(
                                                        'loginfailedNetworkError'),
                                                localizationService
                                                        .isLocalizationLoaded
                                                    ? localizationService
                                                        .getLocalizedString(
                                                            'loginfailed')
                                                    : 'Login Failed',
                                                localizationService
                                                    .selectedLanguageCode,
                                                localizationService);
                                          } else {
                                            Navigator.of(context).pop();

                                            _showLoginFailedDialog(
                                                scale,
                                                context,
                                                loginResult['status'],
                                                localizationService
                                                        .isLocalizationLoaded
                                                    ? localizationService
                                                        .getLocalizedString(
                                                            'loginfailed')
                                                    : 'Login Failed',
                                                localizationService
                                                    .selectedLanguageCode,
                                                localizationService);
                                          }
                                        } else {
                                          _showLoginFailedDialog(
                                              scale,
                                              context,
                                              localizationService
                                                  .getLocalizedString(
                                                      'loginFailedEmpty'),
                                              localizationService
                                                      .isLocalizationLoaded
                                                  ? localizationService
                                                      .getLocalizedString(
                                                          'loginfailed')
                                                  : 'Login Failed',
                                              localizationService
                                                  .selectedLanguageCode,
                                              localizationService);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 65,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      var connectivityResult =
                                          await (Connectivity()
                                              .checkConnectivity());
                                      if (connectivityResult.toString() ==
                                          '[ConnectivityResult.none]') {
                                        _showLoginFailedDialog(
                                            scale,
                                            context,
                                            localizationService
                                                .getLocalizedString(
                                                    'noInternet'),
                                            localizationService
                                                    .isLocalizationLoaded
                                                ? localizationService
                                                    .getLocalizedString(
                                                        'noInternetConnection')
                                                : 'No Internet Connection',
                                            localizationService
                                                .selectedLanguageCode,
                                            localizationService);
                                      } else {
                                        _handleSmartLogin(scale, context,
                                            loginState, localizationService);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FaIcon(FontAwesomeIcons.fingerprint,
                                            size: 40,
                                            color: AppColors.primaryRed),
                                        SizedBox(width: 10),
                                        Icon(Icons.face,
                                            size: 40,
                                            color: AppColors.primaryRed),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: screenSize.height * 0.11,
                            ),
                            _buildTrademarkNotice(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSmartLogin(double scale, BuildContext context,
      LoginState loginState, LocalizationService localizationService) async {
    late final LocalAuthentication auth;

    auth = LocalAuthentication();
    bool isSupported = await auth.isDeviceSupported();
    if (!isSupported) {
      _showLoginFailedDialog(
          scale,
          context,
          localizationService.getLocalizedString('noBiometricSupportBody'),
          localizationService.isLocalizationLoaded
              ? localizationService.getLocalizedString('loginFailed')
              : "Biometric not supported",
          localizationService.selectedLanguageCode,
          localizationService);
      return;
    }
    try {
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      String localizedReason = 'Scan to login';

      // Check for Face ID or Fingerprint biometrics
      if (availableBiometrics.contains(BiometricType.face) ||
          availableBiometrics.contains(BiometricType.weak)) {
        localizedReason = 'Scan your face to login';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        localizedReason = 'Scan your finger to login';
      }

      bool authenticated = await auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        _handleLogin(scale, context, localizationService);

        Map<String, String?> credentials = await getCredentials();
        String? username = credentials['username'];
        String? password = credentials['password'];
        if (username != null && password != null) {
          var loginSuccessful = await loginState.login(username, password);
          if (loginSuccessful["status"] == 200) {
            print("loginSuccessful tt");

            var versionChecker = await PaymentService.getMinVersion();
            if (versionChecker == false) {
              print("App update required");
              Navigator.of(context).pop();
              _showLoginFailedDialog(
                  scale,
                  context,
                  localizationService.getLocalizedString('updateAppBody'),
                  localizationService.isLocalizationLoaded
                      ? localizationService.getLocalizedString('updateAppTitle')
                      : 'Update Required',
                  localizationService.selectedLanguageCode,
                  localizationService);
              return;
            } else {
              print("App is up-to-date.");
              await LOVCompareService.compareAndSyncCurrencies();
              await LOVCompareService.compareAndSyncBanks();
              await PaymentService.getExpiredPaymentsNumber();
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            }
          } else {
            Navigator.of(context).pop();
            _showLoginFailedDialog(
                scale,
                context,
                localizationService
                    .getLocalizedString('WrongCredentialsFoundBody'),
                localizationService.isLocalizationLoaded
                    ? localizationService.getLocalizedString('loginfailed')
                    : "Login Failed",
                localizationService.selectedLanguageCode,
                localizationService);
          }
        } else {
          Navigator.of(context).pop();
          _showLoginFailedDialog(
              scale,
              context,
              localizationService.getLocalizedString('noCredentialsFoundBody'),
              localizationService.isLocalizationLoaded
                  ? localizationService
                      .getLocalizedString('noCredentialsFoundTitle')
                  : "Login Failed",
              localizationService.selectedLanguageCode,
              localizationService);
        }
        print("Authenticated successfully from screen.");
      }
    } on PlatformException catch (e) {
      print("PlatformException during authentication: $e");
    }
  }

  Widget _buildLanguageDropdown(double scale, BuildContext context,
      LocalizationService localizationService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          // Open the PopupMenu when the Row is tapped
          final dynamic state = context.findRenderObject();
          state.showButtonMenu();
        },
        child: PopupMenuButton<String>(
          onSelected: (String newValue) {
            localizationService.selectedLanguageCode = newValue;
          },
          itemBuilder: (BuildContext context) {
            return LoginScreen.languages.map((Map<String, String> language) {
              return PopupMenuItem<String>(
                value: language['code']!,
                child: ListTile(
                  title: Text(
                    language['name']!,
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
              );
            }).toList();
          },
          child: Row(
            children: [
              Icon(Icons.language, color: Colors.black),
              SizedBox(width: 8.0),
              Text(
                getLanguageName(localizationService.selectedLanguageCode),
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getLanguageName(String code) {
    // Function to return the language name based on the language code
    for (var language in LoginScreen.languages) {
      if (language['code'] == code) {
        return language['name']!;
      }
    }
    return ''; // Return empty string if language code not found (should not happen in ideal scenarios)
  }

  // Builds a trademark notice at the bottom or any preferred location of the screen.
  Widget _buildTrademarkNotice() {
    return Text(
      '© Ooredoo 2024',
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Colors.grey,
          fontSize: 14.sp,
          fontFamily: 'NotoSansUI',
          fontWeight: FontWeight.bold),
    );
  }

  void _showLoginFailedDialog(
      double scale,
      BuildContext context,
      String errorMessage,
      String loginFailed,
      String langauage,
      LocalizationService localizationService) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection:
              langauage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: 280.w,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    // Semi-transparent white for glass effect
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Use the minimum space necessary
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        loginFailed,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansUI',
                          color: AppColors.primaryRed,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 14 * scale,
                          fontFamily: 'NotoSansUI',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            localizationService.getLocalizedString("ok"),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * scale,
                              decoration: TextDecoration.none,
                              fontFamily: 'NotoSansUI',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool validateLoginInputs(LoginState loginState) {
    print("validateLoginInputs invoked in loginScreen");
    String username = loginState.username ??
        ''; // Get username from loginState or use an empty string if null
    String password = loginState.password ??
        ''; // Get password from loginState or use an empty string if null

    // Check if username or password is empty
    if (username.isEmpty || password.isEmpty) {
      return false; // Validation failed
    }
    // Additional validation logic can be added here if needed

    return true; // Validation succeeded
  }

  void _handleLogin(double scale, BuildContext context,
      LocalizationService localizationService) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                width: 130.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitFadingCircle(
                      itemBuilder: (BuildContext context, int index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                index.isEven ? Colors.white : Colors.grey[300],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      localizationService.getLocalizedString('pleaseWait'),
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontFamily: 'NotoSansUI',
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 1));
  }
}
