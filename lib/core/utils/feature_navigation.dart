import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/models/feature_item.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/screens/features/product_list_screen.dart';
import 'package:sello/screens/features/product_scan_screen.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

Future<void> openFeature(BuildContext context, FeatureItem feature) async {
  switch (feature.id) {
    case 'voice_cashier':
      context.read<NavigationProvider>().setIndex(1);
      return;
    case 'product_scan':
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProductScanScreen()));
      if (context.mounted) {
        await context.read<DashboardProvider>().load(
          context.read<AuthProvider>().userId,
        );
      }
      return;
    case 'photo_to_content':
      context.read<NavigationProvider>().setIndex(2);
      return;
    case 'business_report':
      context.read<NavigationProvider>().setIndex(3);
      return;
    case 'digital_catalog':
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProductListScreen()));
      if (context.mounted) {
        await context.read<DashboardProvider>().load(
          context.read<AuthProvider>().userId,
        );
      }
      return;
    default:
      AppSnackbar.info(context, '${feature.title} segera hadir.');
  }
}
