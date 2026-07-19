import 'package:flutter/material.dart';

abstract final class Responsive {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;
  static const double contentMaxWidthTablet = 720;
  static const double contentMaxWidthLarge = 960;
  static const double navMaxWidth = 560;

  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isTablet(BuildContext context) =>
      width(context) >= tabletBreakpoint;

  static bool isLargeTablet(BuildContext context) =>
      width(context) >= desktopBreakpoint;

  static double contentMaxWidth(BuildContext context) {
    if (isLargeTablet(context)) return contentMaxWidthLarge;
    if (isTablet(context)) return contentMaxWidthTablet;
    return double.infinity;
  }

  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 32 : 20;

  static int featureGridCount(BuildContext context) {
    if (isLargeTablet(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double featureGridAspectRatio(BuildContext context) =>
      isTablet(context) ? 1.2 : 1.15;

  static double floatingNavBarHeight(BuildContext context) =>
      (isTablet(context) ? 72.0 : 68.0) + 12.0;

  /// Space reserved for [FloatingBottomNav] when [Scaffold.extendBody] is true.
  static double floatingBottomNavInset(BuildContext context) =>
      floatingNavBarHeight(context) + MediaQuery.paddingOf(context).bottom;

  static double bottomScrollPadding(BuildContext context) =>
      floatingBottomNavInset(context) + 8;
}
