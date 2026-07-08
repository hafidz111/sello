import 'package:flutter/material.dart';
import 'package:sello/widgets/common/placeholder_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Laporan Bisnis',
      description:
          'Ringkasan harian dan mingguan dalam bahasa manusia. Contoh: "Minggu ini keripik pedas paling laris, stok tinggal 2 hari lagi."',
      icon: Icons.analytics_rounded,
      color: Color(0xFFF59E0B),
    );
  }
}
