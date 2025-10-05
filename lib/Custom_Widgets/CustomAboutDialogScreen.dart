import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../Services/LocalizationService.dart';
import '../Services/apiConstants.dart';
import '../core/constants.dart';

class CustomAboutDialogScreen extends StatelessWidget {
  final double scale;

  const CustomAboutDialogScreen({
    Key? key,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _contentBox(context),
    );
  }

  Widget _contentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: 20 * scale,
              top: 45 * scale,
              right: 20 * scale,
              bottom: 20 * scale),
          margin: EdgeInsets.only(top: 45 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 10),
                  blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('aboutTitle'),
                style: TextStyle(
                    fontSize: 22 * scale,
                    fontFamily: 'NotoSansUI',
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),

              // 🔹 Version (dynamic)
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink(); // loading placeholder
                  }
                  if (!snapshot.hasData) {
                    return Text(
                      "Version ?",
                      style: TextStyle(
                          fontSize: 14 * scale, fontFamily: 'NotoSansUI'),
                      textAlign: TextAlign.center,
                    );
                  }
                  final version = snapshot.data!.version;
                  final suffix =
                      baseUrl == 'https://b2bpayments.ooredoo.ps' ? " P" : " T";
                  return Text(
                    "$version$suffix",
                    style: TextStyle(
                        fontSize: 14 * scale, fontFamily: 'NotoSansUI'),
                    textAlign: TextAlign.center,
                  );
                },
              ),

              SizedBox(height: 15 * scale),
              Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('aboutBody'),
                style:
                    TextStyle(fontSize: 14 * scale, fontFamily: 'NotoSansUI'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25 * scale),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('ok'),
                    style: TextStyle(
                        fontFamily: 'NotoSansUI',
                        fontSize: 18 * scale,
                        color: AppColors.primaryRed),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20 * scale,
          right: 20 * scale,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 45 * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45 * scale),
              child: Image.asset('assets/images/Init Logo.png'),
            ),
          ),
        ),
      ],
    );
  }
}
