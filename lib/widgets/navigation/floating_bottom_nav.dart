import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/nav_item.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/styles/app_colors.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.items,
  });

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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = currentIndex == index;

                  return _NavBarItem(
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

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.isTablet,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? (isTablet ? 12 : 8) : (isTablet ? 8 : 4),
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: isTablet ? 24 : 22,
                color: isActive
                    ? AppColors.navBarActive
                    : AppColors.navBarInactive,
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: isActive
                      ? (isTablet ? 12 : 11)
                      : (isTablet ? 11 : 10),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.navBarActive
                      : AppColors.navBarInactive,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
