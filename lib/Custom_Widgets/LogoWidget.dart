import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  // Constructor for LogoWidget
  const LogoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the width and height as a percentage of the screen size
    final double logoWidth = MediaQuery.of(context).size.width * 0.5;
    final double logoHeight = MediaQuery.of(context).size.height * 0.25; // Adjust to 25% for a balanced appearance

    // Center the logo and use an AssetImage for better performance and asset management
    return Center(
      child: Image.asset(
        'assets/images/Init Logo.png', // Ensure the asset path is correct
        width: logoWidth,
        height: logoHeight,
      ),
    );
  }
}
