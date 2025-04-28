import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../Services/LocalizationService.dart';
import '../Services/apiConstants.dart';

class CustomAboutDialogScreen extends StatelessWidget {
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
          padding: EdgeInsets.only(left: 20.w, top: 45.h, right: 20.w, bottom: 20.h),
          margin: EdgeInsets.only(top: 45.h),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), offset: Offset(0, 10), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('aboutTitle')} ",
                style: TextStyle(fontSize: 22.sp, fontFamily: 'NotoSansUI', fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              (baseUrl == 'https://b2bpayments.ooredoo.ps') ?
                Text('1.2 P',
                  style: TextStyle(fontSize: 14.sp, fontFamily: 'NotoSansUI'),
                  textAlign: TextAlign.center,
                ):
              Text('1.2 T',
              style: TextStyle(fontSize: 14.sp, fontFamily: 'NotoSansUI'),
              textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),
              Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('aboutBody'),
                style: TextStyle(fontSize: 14.sp, fontFamily: 'NotoSansUI'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 22.h),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
                    style: TextStyle(fontFamily: 'NotoSansUI', fontSize: 18.sp, color: Color(0xFFC62828)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20.w,
          right: 20.w,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 45.h,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45.h)),
              child: Image.asset('assets/images/Init Logo.png'), // Replace with your app's logo or suitable graphic
            ),
          ),
        ),
      ],
    );
  }
}
