import '../Screens/DashboardScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/LocalizationService.dart'; // Import your LocalizationService class
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguageSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LocalizationService localizationService =
        Provider.of<LocalizationService>(context);
    String selectedLanguage =
        localizationService.selectedLanguageCode; // Get selected language code
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828), // Set app bar color to red
        title: Text(
          localizationService.getLocalizedString('languageSettings'),
          style: TextStyle(
              fontFamily: "NotoSansUI",
              fontSize: 18 * scale,
              color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizationService.getLocalizedString('languageSettings'),
                  style: TextStyle(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  localizationService
                      .getLocalizedString('selectPreferredLanguage'),
                  style: TextStyle(
                    fontSize: 18 * scale,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _LanguageCard(
                  scale: scale,
                  flag: '🇸🇦',
                  language: localizationService.getLocalizedString('arabic'),
                  isSelected: selectedLanguage == 'ar',
                  onTap: () {
                    _handleLanguageSelection(context, 'ar');
                  },
                ),
                const SizedBox(height: 16),
                _LanguageCard(
                  scale: scale,
                  flag: '🇬🇧',
                  language: localizationService.getLocalizedString('english'),
                  isSelected: selectedLanguage == 'en',
                  onTap: () {
                    _handleLanguageSelection(context, 'en');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLanguageSelection(BuildContext context, String languageCode) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent user from dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFFC62828)), // Customize color if needed
            ),
          ),
        );
      },
    );

    // Delay language update until after loading indicator is dismissed
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the dialog
      Provider.of<LocalizationService>(context, listen: false)
          .selectedLanguageCode = languageCode;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DashboardScreen())); // Navigate to DashboardPage
    });
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _LanguageCard({
    required this.flag,
    required this.language,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                flag,
                style: TextStyle(fontSize: 18 * scale),
              ),
              const SizedBox(width: 16),
              Text(
                language,
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: isSelected ? const Color(0xFFC62828) : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
