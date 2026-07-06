import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/feature_data.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/feature_card.dart';
import 'package:sello/widgets/common/logout_button.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final userName = context.watch<AuthProvider>().userName ?? 'Pengguna';
    final bottomPad = Responsive.bottomScrollPadding(context);
    final isTablet = Responsive.isTablet(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding, 20, padding, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Halo, $userName — semua fitur Sello',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                const LogoutButton(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, bottomPad),
          sliver: isTablet
              ? SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FeatureCard(
                      feature: FeatureData.all[index],
                      onTap: () {},
                    ),
                    childCount: FeatureData.all.length,
                  ),
                )
              : SliverList.separated(
                  itemCount: FeatureData.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return FeatureCard(
                      feature: FeatureData.all[index],
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }
}
