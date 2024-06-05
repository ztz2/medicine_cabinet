import 'package:flutter/material.dart';

class Box extends StatelessWidget {
  double? height = 1;
  double? width = 1;
  Color? backgroundColor = Colors.transparent;
  Widget? child;
  EdgeInsetsGeometry? margin;
  BorderRadius? borderRadius;


  Box({
    super.key,
    this.height,
    this.width,
    this.margin,
    this.backgroundColor,
    this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: PhysicalModel(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: child
      ),
    );
  }
}
