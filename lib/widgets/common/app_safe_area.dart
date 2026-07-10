import 'package:flutter/material.dart';
import 'package:sello/widgets/common/responsive_center.dart';

class AppSafeArea extends StatelessWidget {
  const AppSafeArea({
    super.key,
    required this.child,
    this.bottom = false,
    this.responsive = true,
    this.maxWidth,
  });

  final Widget child;
  final bool bottom;
  final bool responsive;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final content = responsive
        ? ResponsiveCenter(maxWidth: maxWidth, child: child)
        : child;

    return SafeArea(bottom: bottom, child: content);
  }
}
