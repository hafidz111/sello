import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/nav_item.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/navigation/cashier_mode_sheet.dart';
import 'package:sello/widgets/navigation/navbar_item.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({super.key, required this.items});

  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<NavigationProvider>().currentIndex;
    final isTablet = Responsive.isTablet(context);
    final horizontalPadding = isTablet ? 48.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.navMaxWidth),
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: isTablet ? 72 : 68,
              decoration: BoxDecoration(
                color: AppColors.navBarBackground,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navBarShadow,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  if (item.isCenter) {
                    return NavBarCenterItem(
                      item: item,
                      isTablet: isTablet,
                      onTap: () => showCashierModeSheet(context),
                    );
                  }

                  final isActive = currentIndex == index;
                  return NavBarItem(
                    item: item,
                    isActive: isActive,
                    isTablet: isTablet,
                    onTap: () =>
                        context.read<NavigationProvider>().setIndex(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
