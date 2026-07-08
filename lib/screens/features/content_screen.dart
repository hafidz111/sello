import 'package:flutter/material.dart';
import 'package:sello/widgets/common/placeholder_screen.dart';

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Foto ke Konten',
      description:
          'Unggah foto produk dan AI akan menghasilkan caption Instagram/TikTok, hashtag lokal, dan copy iklan marketplace.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFEC4899),
    );
  }
}
