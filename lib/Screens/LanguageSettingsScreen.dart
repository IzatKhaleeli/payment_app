import '../Screens/DashboardScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/LocalizationService.dart'; // Import your LocalizationService class
import 'package:flutter_screenutil/flutter_screenutil.dart';
class LanguageSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LocalizationService localizationService = Provider.of<LocalizationService>(context);
    String selectedLanguage = localizationService.selectedLanguageCode; // Get selected language code

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFA60016), // Set app bar color to red
        title: Text(
          localizationService.getLocalizedString('languageSettings'),
          style: TextStyle(fontFamily: "NotoSansUI", fontSize: 18.sp, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Set back arrow icon color to white
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  localizationService.getLocalizedString('selectPreferredLanguage'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _LanguageCard(
                  flag: '🇸🇦', // Replace with actual flag icon or image
                  language: localizationService.getLocalizedString('arabic'),
                  isSelected: selectedLanguage == 'ar',
                  onTap: () {
                    _handleLanguageSelection(context, 'ar');
                  },
                ),
                SizedBox(height: 16),
                _LanguageCard(
                  flag: '🇬🇧', // Replace with actual flag icon or image
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
      barrierDismissible: false, // Prevent user from dismissing dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA60016)), // Customize color if needed
            ),
          ),
        );
      },
    );

    // Delay language update until after loading indicator is dismissed
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close the dialog
      Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode = languageCode;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen())); // Navigate to DashboardPage
    });
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.language,
    required this.isSelected,
    required this.onTap,
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
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: 16),
              Text(
                language,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color(0xFFC62828) : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
