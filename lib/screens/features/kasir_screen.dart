import 'package:flutter/material.dart';
import 'package:sello/widgets/common/placeholder_screen.dart';

class KasirScreen extends StatelessWidget {
  const KasirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Kasir Suara & Teks Cerdas',
      description:
          'Catat penjualan dengan kalimat natural seperti "Tadi jual 5 keripik Rp 10 ribu". AI akan mengekstrak item, harga, dan stok secara otomatis.',
      icon: Icons.mic_rounded,
    );
  }
}
