import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/models/cashier_mode.dart';
import 'package:sello/models/feature_item.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/screens/features/education_screen.dart';
import 'package:sello/screens/features/product_list_screen.dart';
import 'package:sello/widgets/common/app_snackbar.dart';

Future<void> openFeature(BuildContext context, FeatureItem feature) async {
  switch (feature.id) {
    case 'cashier':
    case 'voice_cashier':
      context.read<NavigationProvider>().openCashier();
      return;
    case 'product_scan':
      context.read<NavigationProvider>().openCashier(mode: CashierMode.scan);
      return;
    case 'photo_to_content':
      context
          .read<NavigationProvider>()
          .setIndex(NavigationProvider.kontenIndex);
      return;
    case 'business_report':
      context
          .read<NavigationProvider>()
          .setIndex(NavigationProvider.laporanIndex);
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
    case 'micro_education':
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EducationScreen()));
      return;
    default:
      AppSnackbar.info(context, '${feature.title} segera hadir.');
  }
}
