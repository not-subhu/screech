import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/tasks_screen.dart';
import '../screens/habits_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/coin_badge.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    TasksScreen(),
    HabitsScreen(),
    ShopScreen(),
    StatsScreen(),
  ];

  static const _titles = ['Quests', 'Habits', 'Shop', 'Stats'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(_navIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.rarityStripe.createShader(bounds),
              child: Text(
                'Questify',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white, // masked by shader
                    ),
              ),
            ),
          ],
        ),
        actions: const [
          CoinBadge(),
          SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: navIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgDeep,
          border: Border(
            top: BorderSide(
                color: AppColors.surfaceBorder.withOpacity(0.5), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navIndex,
          onDestinationSelected: (i) =>
              ref.read(_navIndexProvider.notifier).state = i,
          backgroundColor: AppColors.bgDeep,
          indicatorColor: AppColors.sakura.withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined,
                  color: AppColors.textMuted),
              selectedIcon:
                  Icon(Icons.auto_stories, color: AppColors.sakura),
              label: 'Quests',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined,
                  color: AppColors.textMuted),
              selectedIcon: Icon(Icons.local_fire_department,
                  color: AppColors.mint),
              label: 'Habits',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined,
                  color: AppColors.textMuted),
              selectedIcon: Icon(Icons.storefront, color: AppColors.coinGold),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined,
                  color: AppColors.textMuted),
              selectedIcon:
                  Icon(Icons.bar_chart, color: AppColors.textPrimary),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}
