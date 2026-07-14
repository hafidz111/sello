import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/models/nav_item.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/screens/features/cashier_screen.dart';
import 'package:sello/screens/features/content_screen.dart';
import 'package:sello/screens/features/report_screen.dart';
import 'package:sello/screens/menu/menu_screen.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_safe_area.dart';
import 'package:sello/widgets/navigation/floating_bottom_nav.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _navItems = [
    NavItem(
      label: 'Beranda',
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale_rounded,
    ),
    NavItem(
      label: 'Laporan',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    NavItem(
      label: 'Scan',
      icon: Icons.qr_code_scanner_rounded,
      activeIcon: Icons.qr_code_scanner_rounded,
      isCenter: true,
    ),
    NavItem(
      label: 'Konten',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
    ),
    NavItem(
      label: 'Menu',
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_rounded,
    ),
  ];

  static const _screens = [
    CashierScreen(),
    ReportScreen(),
    ContentScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenIndex = context.watch<NavigationProvider>().screenIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: AppSafeArea(
              bottom: false,
              child: IndexedStack(
                index: screenIndex,
                children: _screens,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FloatingBottomNav(items: _navItems),
            ),
          ),
        ],
      ),
    );
  }
}
