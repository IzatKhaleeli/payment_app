import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';
import 'LoginScreen.dart';
import 'PaymentHistoryScreen.dart';
import 'RecordPaymentScreen.dart';
import 'SettingsScreen.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DashboardItemModel> dashboardItems = []; // Initialize as empty list
  late SharedPreferences prefs; // SharedPreferences instance
  String? usernameLogin; // State variable to hold the username
  Timer? _timer; // Timer instance



  @override
  void initState() {
    print("dashboard page");
    super.initState();
    _initializeLocalization();
    _getUsername();
    _initializeDashboardItems();
    _scheduleDailyTask();
  }

  void _scheduleDailyTask() {
    // Calculate the time until the next 12:30 PM
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day, 23, 59);

    // If it's already past 12:30 PM today, schedule for tomorrow
    if (now.isAfter(nextRun)) {
      nextRun.add(Duration(days: 1));
    }

    // Calculate the duration until the next run
    final durationUntilNextRun = nextRun.difference(now);

    // Schedule the timer to run daily
    _timer = Timer.periodic(
      durationUntilNextRun,
          (Timer timer) {
        PaymentService.getExpiredPaymentsNumber();
        // Schedule next execution after 24 hours
        _timer?.cancel(); // Cancel the previous timer
        _timer = Timer.periodic(Duration(days: 1), (Timer timer) {
          PaymentService.getExpiredPaymentsNumber();
        });
      },
    );
  }

  Future<void> _getUsername() async {
    prefs = await SharedPreferences.getInstance();
    String? storedUsername = prefs.getString('usernameLogin');
    setState(() {
      usernameLogin = storedUsername;
    });

    // Start the periodic network test with context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (usernameLogin != null && usernameLogin!.isNotEmpty) {
        PaymentService.startPeriodicNetworkTest(context);
      }
    });
  }

  Future<void> _initializeLocalization() async {
    await Provider.of<LocalizationService>(context, listen: false).initLocalization();
  }

  void _initializeDashboardItems() {

    dashboardItems = [
      DashboardItemModel(iconData: Icons.payment, title: 'recordPayment', onTap: () => _navigateTo(RecordPaymentScreen())),
      DashboardItemModel(iconData: Icons.history, title: 'paymentHistory', onTap: () => _navigateTo(PaymentHistoryScreen())),
      DashboardItemModel(iconData: Icons.settings, title: 'settings', onTap: () => _navigateTo(SettingsScreen())),
    ];
  }

  @override
  Widget build(BuildContext context)  {
    ScreenUtil.init(context, designSize: Size(360, 690));
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = screenSize.width / (screenSize.height-180);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
        leading: IconButton(
          iconSize: 34,
          icon: Icon(
            Icons.logout_outlined,
            color: Color(0xffd21816),
          ),
          onPressed: () {
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
          },
        ),
        title: Image.asset(
          'assets/images/logo_ooredoo.png',
          fit: BoxFit.contain,
          height: AppBar().preferredSize.height * 2,
        ),
        centerTitle: true,
      ),

      body:
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(6.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),

                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person,
                    color: Color(0xFFC62828),
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('hello')} $usernameLogin',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: "NotoSansUI",
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),
          ),


          // Add some spacing between the message and the GridView
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio:  (aspectRatio*3),
              ),
              itemCount: dashboardItems.length,
              itemBuilder: (context, index) {
                return Consumer<LocalizationService>(
                  builder: (context, localizationService, _) {
                    return DashboardItem(
                      iconData: dashboardItems[index].iconData,
                      title: localizationService.getLocalizedString(dashboardItems[index].title),
                      onTap: () async {
                        switch (dashboardItems[index].title) {
                          case 'recordPayment':
                            _navigateTo(RecordPaymentScreen());
                            break;
                          case 'paymentHistory':
                            _navigateTo(PaymentHistoryScreen());
                            break;
                          case 'settings':
                            _navigateTo(SettingsScreen());
                            break;

                          default:
                            break;
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildLogoutDialogContent(BuildContext context) {
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
                    onPressed: () => Navigator.of(context).pop(), // Close the dialog
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

class DashboardItemModel {
  final IconData iconData;
  final String title;

  DashboardItemModel({required this.iconData, required this.title, required void Function() onTap});
}

class DashboardItem extends StatefulWidget {
  final IconData iconData;
  final String title;
  final VoidCallback onTap;

  const DashboardItem({
    Key? key,
    required this.iconData,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  _DashboardItemState createState() => _DashboardItemState();
}

class _DashboardItemState extends State<DashboardItem> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => isTapped = true),
      onTapCancel: () => setState(() => isTapped = false),
      onTapUp: (_) => setState(() => isTapped = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isTapped ? Color(0xFFC62828) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              offset: Offset(0, 3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.iconData, size: 40.sp, color: isTapped ? Colors.white : Color(0xFFC62828)),
              SizedBox(height: 4.h),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  overflow: TextOverflow.clip ,
                  fontFamily: 'NotoSansUI',
                  color: isTapped ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }
