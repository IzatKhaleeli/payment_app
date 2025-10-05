import 'package:flutter/material.dart';

import '../core/constants.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  const CustomTextField({
    required this.hint,
    required this.icon,
    this.obscureText = false,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText; // Initially uses the value from widget
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured; // Toggle the obscured state
    });
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
        fontSize: 16, color: Colors.black87, fontFamily: 'NotoSansUI');
    const hintStyle = TextStyle(color: Colors.black45);
    final borderRadius = BorderRadius.circular(8);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        obscureText: _isObscured,
        onChanged: widget.onChanged,
        style: textStyle,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: hintStyle,
          prefixIcon: Icon(widget.icon, color: AppColors.primaryRed),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility),
                  color: AppColors.primaryRed,
                  onPressed: _togglePasswordVisibility,
                )
              : null, // Only add the toggle icon if obscureText is initially true
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(18.0),
          border: OutlineInputBorder(
              borderRadius: borderRadius, borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: AppColors.primaryRed, width: 1),
          ),
        ),
      ),
    );
  }
}
