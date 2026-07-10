import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/feature_data.dart';
import 'package:sello/core/utils/feature_navigation.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/widgets/common/feature_card.dart';
import 'package:sello/widgets/features/home/home_header.dart';
import 'package:sello/widgets/features/home/home_quick_stats.dart';
import 'package:sello/widgets/features/home/home_section_title.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName ?? 'Pengguna';
    final padding = Responsive.horizontalPadding(context);
    final gridCount = Responsive.featureGridCount(context);
    final bottomPad = Responsive.bottomScrollPadding(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HomeHeader(userName: userName, padding: padding),
        ),
        SliverToBoxAdapter(child: HomeQuickStats(padding: padding)),
        SliverToBoxAdapter(
          child: HomeSectionTitle(title: 'Fitur Utama', padding: padding),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: Responsive.featureGridAspectRatio(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final feature = FeatureData.all[index];
                return FeatureCard(
                  feature: feature,
                  compact: true,
                  onTap: () => openFeature(context, feature),
                );
              },
              childCount: FeatureData.all.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: HomeSectionTitle(title: 'Semua Fitur', padding: padding),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, bottomPad),
          sliver: SliverList.separated(
            itemCount: FeatureData.all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return FeatureCard(
                feature: FeatureData.all[index],
                onTap: () => openFeature(context, FeatureData.all[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
