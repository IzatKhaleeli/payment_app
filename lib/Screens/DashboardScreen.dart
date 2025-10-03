import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ooredoo_app/Screens/dashboard_item.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/LoginState.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';
import 'payment_history/PaymentHistoryScreen.dart';
import 'recordPayment/RecordPaymentScreen.dart';
import 'SettingsScreen.dart';
import 'record_diconnected_payment/record_diconnected_payment.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<DashboardItemModel> dashboardItems = [];
  late SharedPreferences prefs;
  String? usernameLogin;
  Timer? _timer;
  int hasDisconnectedPermission = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocalization();
    _getUsername();
    _initializeDashboardItems();
    _scheduleDailyTask();
    _loadPermission();
  }

  void _scheduleDailyTask() {
    final now = DateTime.now();
    final nextRun = DateTime(now.year, now.month, now.day, 23, 59);

    if (now.isAfter(nextRun)) {
      nextRun.add(Duration(days: 1));
    }

    final durationUntilNextRun = nextRun.difference(now);

    _timer = Timer.periodic(
      durationUntilNextRun,
      (Timer timer) {
        PaymentService.getExpiredPaymentsNumber();
        _timer?.cancel();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (usernameLogin != null && usernameLogin!.isNotEmpty) {
        PaymentService.startPeriodicNetworkTest(context);
      }
    });
  }

  Future<void> _initializeLocalization() async {
    await Provider.of<LocalizationService>(context, listen: false)
        .initLocalization();
  }

  void _initializeDashboardItems() {
    dashboardItems = [
      DashboardItemModel(
          iconData: Icons.payment,
          title: 'recordPayment',
          onTap: () => _navigateTo(RecordPaymentScreen())),
      DashboardItemModel(
          iconData: Icons.payment,
          title: 'recordPaymentDisconnected',
          onTap: () => _navigateTo(RecordPaymentDisconnectedScreen())),
      DashboardItemModel(
          iconData: Icons.history,
          title: 'paymentHistory',
          onTap: () => _navigateTo(PaymentHistoryScreen())),
      DashboardItemModel(
          iconData: Icons.settings,
          title: 'settings',
          onTap: () => _navigateTo(SettingsScreen())),
    ];
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
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _loadPermission() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasDisconnectedPermission = prefs.getInt('disconnectedPermission') ?? 0;
    });
    print("Loaded hasDisconnectedPermission: $hasDisconnectedPermission");
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

    final filteredDashboardItems = dashboardItems.where((item) {
      if (item.title == 'recordPaymentDisconnected' &&
          hasDisconnectedPermission != 1) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
        leading: IconButton(
          iconSize: 34,
          icon: const Icon(
            Icons.logout_outlined,
            color: Color(0xFFC62828),
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
                    child: _buildLogoutDialogContent(dialogContext, scale),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person,
                    color: const Color(0xFFC62828),
                    size: 24 * scale,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('hello')} $usernameLogin',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontFamily: "NotoSansUI",
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availableHeight = constraints.maxHeight;

                final double spacing =
                    10.h * (filteredDashboardItems.length - 1);
                final double itemHeight = (availableHeight - spacing - 32) /
                    filteredDashboardItems.length;

                final double itemWidth = constraints.maxWidth - 32;

                final double aspectRatio = itemWidth / itemHeight;

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: aspectRatio, // dynamic height
                  ),
                  itemCount: filteredDashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredDashboardItems[index];

                    return Consumer<LocalizationService>(
                      builder: (context, localizationService, _) {
                        return DashboardItem(
                          scale: scale,
                          iconData: item.iconData,
                          title: localizationService
                              .getLocalizedString(item.title),
                          onTap: () async {
                            switch (item.title) {
                              case 'recordPayment':
                                _navigateTo(RecordPaymentScreen());
                                break;
                              case 'recordPaymentDisconnected':
                                _navigateTo(RecordPaymentDisconnectedScreen());
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutDialogContent(BuildContext context, double scale) {
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
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('logoutBody'),
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontFamily: "NotoSansUI",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialogButton(
                      context: context,
                      label: Provider.of<LocalizationService>(context,
                              listen: false)
                          .getLocalizedString('cancel'),
                      onPressed: () =>
                          Navigator.of(context).pop(), // Close the dialog
                      backgroundColor: Colors.grey.shade300,
                      textColor: Colors.black,
                      scale: scale),
                  _buildDialogButton(
                      context: context,
                      label: Provider.of<LocalizationService>(context,
                              listen: false)
                          .getLocalizedString('logout'),
                      onPressed: () async {
                        PaymentService.showLoadingOnly(context, scale);

                        var connectivityResult =
                            await (Connectivity().checkConnectivity());
                        if (connectivityResult.toString() !=
                            '[ConnectivityResult.none]') {
                          try {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String? tokenID = prefs.getString('token');

                            String finalLogout =
                                "${apiUrlLogout}?token=${tokenID}";
                            NetworkHelper helper =
                                NetworkHelper(url: finalLogout);
                            var logoutStatus = await helper.getData();
                          } catch (e) {
                            print("logout failed :${e}");
                          } finally {
                            PaymentService.completeLogout(context);
                          }
                        } else
                          PaymentService.completeLogout(context);
                      },
                      backgroundColor: Color(0xFFC62828),
                      textColor: Colors.white,
                      scale: scale),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(
      {required BuildContext context,
      required String label,
      required VoidCallback onPressed,
      required Color backgroundColor,
      required Color textColor,
      required double scale}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: "NotoSansUI", color: textColor, fontSize: 14 * scale),
      ),
    );
  }
}
