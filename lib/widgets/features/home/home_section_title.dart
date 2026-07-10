import 'package:flutter/material.dart';
import 'package:sello/styles/app_text_styles.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    required this.padding,
  });

  final String title;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 12),
      child: Text(title, style: AppTextStyles.titleLarge),
    );
  }
}
