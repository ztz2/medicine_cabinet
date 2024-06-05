import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medicine_cabinet/util/hexto_color.dart';
import 'package:medicine_cabinet/util/screen_helper.dart';

class Input extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final Color? color;
  final EdgeInsets padding;
  final double? height;
  final double? fontSize;
  final TextEditingController? controller;
  // final int? maxLength;
  // final bool? maxLengthEnforced;

  const Input({
    super.key,
    this.hintText = "必填项",
    this.obscureText = false,
    this.onChanged,
    this.controller,
    this.height,
    this.fontSize,
    this.keyboardType,
    this.color,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    ScreenHelper.init(context);
    return Material(child: _input());
  }

  _input() {
    var fontSizeValue = fontSize ?? 14.px;
    return Container(
      padding: padding,
      height: height,
      child: Center(
        child: TextField(
          onChanged: onChanged,
          obscureText: obscureText,
          controller: controller,
          keyboardType: keyboardType,
          // autofocus: !obscureText,
          // cursorColor: hexToColor("#009788"),
          style: TextStyle(
            fontSize: fontSizeValue,
            color: color,
            fontWeight: FontWeight.w400
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: fontSizeValue,
              color: hexToColor("#c9ccd0"),
              fontWeight: FontWeight.w400
            ),
          ),
        ),
      )
    );
  }
}
