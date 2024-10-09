import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ooredoo_app/Services/apiConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/LanguageSettingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../Custom_Widgets/CustomAboutDialogScreen.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import '../Services/networking.dart';
import 'LoginScreen.dart';


class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));

    Widget _buildSettingSection(String title, List<Widget> options, LocalizationService localizationService) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 16.h),
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 6,
              offset: Offset(0, 2), // subtle shadow for depth
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Text(
                localizationService.getLocalizedString(title.toLowerCase()),
                style: TextStyle(fontFamily: "NotoSansUI", fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
            ...options,
          ],
        ),
      );
    }

    Widget _buildSettingOption(IconData icon, String title, {VoidCallback? onTap, LocalizationService? localizationService}) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Color(0xFFC62828), size: 24.sp),
                  SizedBox(width: 20.w),
                  Text(
                    localizationService!.getLocalizedString(title),
                    style: TextStyle(fontFamily: "NotoSansUI", fontSize: 16.sp),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider<LocalizationService>(
      create: (_) {
        var localizationState = LocalizationService();
        localizationState.initLocalization(); // Initialize localization
        return localizationState;
      },
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
          return Directionality(
            textDirection: localizationService.selectedLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  localizationService.getLocalizedString('settings'),
                  style: TextStyle(fontFamily: "NotoSansUI", fontSize: 18.sp, color: Colors.white),
                ),
                backgroundColor: Color(0xFFA60016),
                elevation: 0,
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSettingSection('Preferences', [
                      _buildSettingOption(Icons.language, 'languageSettings', onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(milliseconds: 300), // Adjust as necessary
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(1.0, 0.0), // From right to left
                                  end: Offset.zero,
                                ).animate(animation),
                                child: LanguageSettingsScreen(),
                              );
                            },
                          ),
                        );
                     //   _handleChangeLanguage(context,localizationService);
                      }, localizationService: localizationService),
                    ], localizationService),
                    _buildSettingSection('Other', [
                      _buildSettingOption(Icons.info_outline, 'aboutHelp', onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return Dialog(
                              insetPadding: EdgeInsets.symmetric(horizontal: 16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              child: CustomAboutDialogScreen(),
                            );
                          },
                        );
                      }, localizationService: localizationService),

                    ], localizationService),
                    _buildSettingSection('Account', [
                      _buildSettingOption(Icons.logout, 'logout', onTap: () {
                        _showLogoutDialog(context);
                      }, localizationService: localizationService),

                    ], localizationService),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildLogoutDialogContent(dialogContext),
          ),
        );
      },
    );
  }
  Widget _buildLogoutDialogContent(BuildContext context ,) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.44),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Provider.of<LocalizationService>(context, listen: false).getLocalizedString('logoutBody'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: "NotoSansUI",
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Ooredoo theme color
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialogButton(
                    context: context,
                    label: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: Colors.grey.shade300,
                    textColor: Colors.black,
                  ),
                  _buildDialogButton(
                    context: context,
                    label: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('logout'),
                    onPressed: () async {
                      var connectivityResult = await (Connectivity().checkConnectivity());
                      print("connectivityResult :${connectivityResult}");
                      if(connectivityResult.toString() != '[ConnectivityResult.none]'){
                        print("logout have internet");
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        String? tokenID = prefs.getString('token');
                        print("logout token to delete :${tokenID}");

                        if (tokenID == null) {
                          print('Token not found');
                          return;
                        }
                        String finalLogout ="${apiUrlLogout}?token=${tokenID}";
                        print("url :${finalLogout}");

                        NetworkHelper helper = NetworkHelper(url: finalLogout);
                        try {
                          var logoutStatus = await helper.getData();
                          print("logout.status :${logoutStatus}");
                        }
                        catch (e) {
                          print("logout failed :${e}");
                          return ;
                        }
                      }
                          PaymentService.showLoadingAndNavigate(context);
                    },
                    backgroundColor: Color(0xFFC62828), // Ooredoo theme color
                    textColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: TextStyle(fontFamily: "NotoSansUI", color: textColor)),
    );
  }
}