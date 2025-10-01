import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardItemModel {
  final IconData iconData;
  final String title;

  DashboardItemModel(
      {required this.iconData,
      required this.title,
      required void Function() onTap});
}

class DashboardItem extends StatefulWidget {
  final IconData iconData;
  final String title;
  final VoidCallback onTap;
  final double scale;

  const DashboardItem({
    Key? key,
    required this.iconData,
    required this.title,
    required this.scale,
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
          color: isTapped ? const Color(0xFFC62828) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              offset: const Offset(0, 3),
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
              Icon(widget.iconData,
                  size: 40 * widget.scale,
                  color: isTapped ? Colors.white : const Color(0xFFC62828)),
              SizedBox(height: 4.h),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  overflow: TextOverflow.clip,
                  fontFamily: 'NotoSansUI',
                  color: isTapped ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w300,
                  fontSize: 16 * widget.scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
