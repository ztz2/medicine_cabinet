import 'package:flutter/material.dart';

Color hexToColor(String hexString, {double opacity = 1}) {
  final int alphaValue = (opacity * 255).round();
  final String alphaHex = alphaValue.toRadixString(16).padLeft(2, '0');
  String hexColor = hexString;
  if (hexColor.startsWith("#")) {
    hexColor = hexString.replaceAll('#', '');
  }
  return Color(int.parse('$alphaHex$hexColor', radix: 16));
}
