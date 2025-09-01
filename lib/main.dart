import 'package:flutter/services.dart';

import '../Models/LoginState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Screens/SplashScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Services/LocalizationService.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  
  LocalizationService localizeService = LocalizationService();
  bool isJailbroken=false;
  bool developerMode=false;
  try {
    isJailbroken = await FlutterJailbreakDetection.jailbroken;
    developerMode = await FlutterJailbreakDetection.developerMode;
    print("developer mode :${developerMode} : isJailbroken :${isJailbroken}");

  }
  on PlatformException{
    isJailbroken = true;
    developerMode = true;
  }
  catch (e) {
    print("Error localization Jailbroken: $e");
  }

  if (isJailbroken) {
    runApp(MyApp(isJailbroken: true));
  }
  else {
    try {
      await localizeService.initLocalization();
    } catch (e) {
      print("Error initializing localization: $e");
    }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalizationService()),
        ChangeNotifierProvider(create: (context) => LoginState()),
      ],
      child: const MyApp(isJailbroken: false),
    ),
  );
  }
}

class MyApp extends StatelessWidget {
  final bool isJailbroken;

  const MyApp({super.key, required this.isJailbroken});
  @override
  Widget build(BuildContext context) {
    const Color primaryRed =
        Color(0xFFD32F2F);
    const Color backgroundGrey =
        Color(0xFFF7F7F7);
    const Color inputFieldGrey =
        Color(0xFFE0E0E0); 
    final ThemeData theme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: const ColorScheme.light().copyWith(
        primary: primaryRed,
        onPrimary: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFieldGrey,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryRed.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
      ),
      textTheme: TextTheme(
        titleMedium: TextStyle(color: primaryRed, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.black),
      ),
    );
    if (isJailbroken) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'This application cannot be run on jailbroken devices.',
              style: TextStyle(color: Color(0xFFC62828), fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Consumer<LocalizationService>(
      builder: (context, localizeService, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OoPay', // App title
          theme: theme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'), // English
            Locale('ar', 'AE'), // Arabic
            // Add more locales as needed
          ],
          locale: Locale(localizeService.selectedLanguageCode),
          home: SplashScreen(),
          builder: (context, child) {
            return Directionality(
              textDirection: localizeService.selectedLanguageCode == 'en'
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              child: child!,
            );

          },
        );
      },
    );
  }
}
