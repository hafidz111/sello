import 'package:flutter/material.dart';

import '../../models/nav_item.dart';
import '../../styles/app_colors.dart';

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    super.key,
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
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? (isTablet ? 10 : 6) : (isTablet ? 6 : 2),
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : Colors.transparent,
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
                      ? (isTablet ? 12 : 10)
                      : (isTablet ? 11 : 9),
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

class NavBarCenterItem extends StatelessWidget {
  const NavBarCenterItem({
    super.key,
    required this.item,
    required this.isTablet,
    required this.onTap,
  });

  final NavItem item;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isTablet ? 56.0 : 52.0;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                item.activeIcon,
                color: AppColors.textOnPrimary,
                size: isTablet ? 28 : 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
