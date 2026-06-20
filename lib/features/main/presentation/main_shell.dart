import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sound_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../ranking/presentation/ranking_screen.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../menu/presentation/menu_bottom_sheet.dart';

final _tabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // tab inicial é 0 (Home) — sem música
  }

  @override
  void dispose() {
    ref.read(soundServiceProvider).stopBackground();
    super.dispose();
  }

  Future<void> _onTabChanged(int index) async {
    ref.read(_tabIndexProvider.notifier).state = index;
    final sound = ref.read(soundServiceProvider);
    if (index == 0) {
      await sound.stopBackground();
    } else {
      await sound.playBackground(BackgroundMusic.menu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(_tabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: tabIndex,
        children: const [
          HomeScreen(),
          RankingScreen(),
          ProfileScreen(),
          ShopScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: tabIndex,
        onTap: _onTabChanged,
        onMenuTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const MenuBottomSheet(),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onMenuTap;

  const _BottomNav({required this.currentIndex, required this.onTap, required this.onMenuTap});

  static const _items = [
    (Icons.home_outlined,        Icons.home,             'Home'),
    (Icons.leaderboard_outlined, Icons.leaderboard,      'Ranking'),
    (Icons.person_outline,       Icons.person,           'Perfil'),
    (Icons.storefront_outlined,  Icons.storefront,       'Loja'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (outlinedIcon, filledIcon, label) = _items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? filledIcon : outlinedIcon,
                        size: 22,
                        color: isActive ? AppColors.selectionPurple : AppColors.textMuted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.selectionPurple : AppColors.textMuted,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        width: 20,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.selectionPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
