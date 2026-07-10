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
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? (isTablet ? 12 : 8) : (isTablet ? 8 : 4),
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
