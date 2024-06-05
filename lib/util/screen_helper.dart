import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///扩展int以方便使用
extension IntFit on int {
  ///eg: 200.gx
  double get px {
    return ScreenHelper.getPx(toDouble());
  }
}
///扩展double以方便使用
extension DoubleFit on double {
  ///eg: 200.0. px
  double get px {
    return ScreenHelper.getPx(this);
  }
}

///屏幕适配工具类，如果UI要求要和UI稿完全-致的还原度时可以使用
class ScreenHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double ratio;
  /// 根据设计稿实际宽度初始化
  /// baseWidth 设计稿宽度
  static void init (BuildContext context, {double baseWidth = 375}) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size . height;
    ratio = screenWidth / baseWidth;
  }
  /// 获取设计稿对应的大小
  /// size是设计稿大小
  static double getPx(double size) {
    return ScreenHelper.ratio * size;
  }
}
