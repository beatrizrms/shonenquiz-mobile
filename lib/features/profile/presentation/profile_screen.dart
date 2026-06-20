import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/user_hero_card.dart';
import '../data/user_profile.dart';
import '../providers/profile_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../menu/presentation/menu_bottom_sheet.dart';

String _fmtScore(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onMenuTap: () => showModalBottomSheet(
                context: context, isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const MenuBottomSheet(),
              ),
            ),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Falha ao carregar perfil', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userProfileProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
                data: (profile) => _ProfileContent(profile: profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  const _TopBar({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Text('PERFIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .15)),
          const Spacer(),
          GestureDetector(
            onTap: onMenuTap,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.menu_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final sessionsAsync = ref.watch(recentSessionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userStatsProvider);
        ref.invalidate(recentSessionsProvider);
        await Future.wait([
          ref.read(userProfileProvider.future).then((_) {}, onError: (_) {}),
          ref.read(userStatsProvider.future).then((_) {}, onError: (_) {}),
          ref.read(recentSessionsProvider.future).then((_) {}, onError: (_) {}),
        ]);
      },
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          UserHeroCard(profile: profile, catName: ref.watch(catNameProvider).valueOrNull),
          const SizedBox(height: 12),
          _InventoryButton(),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => _StatsGridSkeleton(),
            error: (_, __) => _StatsGrid.empty(profile: profile),
            data: (stats) => _StatsGrid(profile: profile, stats: stats),
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _AchievementsSection(profile: profile, stats: stats),
          ),
          const SizedBox(height: 20),
          sessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (sessions) => sessions.isEmpty ? const SizedBox.shrink() : _RecentHistory(sessions: sessions),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


class _InventoryButton extends StatelessWidget {
  const _InventoryButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InventoryScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.lightPurple),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventário', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text('Habilidades, sets e acessórios', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const _CurrencyBadge({required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(6, (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
      )),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final UserProfile profile;
  final UserStats? stats;

  const _StatsGrid({required this.profile, this.stats});
  const _StatsGrid.empty({required this.profile}) : stats = null;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${stats?.totalSessions ?? 0}', 'Partidas\njogadas'),
      ('${stats?.accuracy ?? 0}%', 'Precisão\ngeral'),
      ('🔥 ${stats?.maxCombo ?? 0}', 'Maior\nsequência'),
      (_fmtScore(stats?.totalScore ?? 0), 'Pontos\ntotais'),
      ('${profile.leagueLabel.split(' ').last}', 'Liga\natual'),
      ('${profile.xp}', 'XP\nacumulado'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((s) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.$1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 3),
            Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
          ],
        ),
      )).toList(),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final UserProfile profile;
  final UserStats stats;

  const _AchievementsSection({required this.profile, required this.stats});

  List<(String, String, bool)> _compute() => [
    ('🔥', 'Combo ×10',       stats.maxCombo >= 10),
    ('🎯', '100% precisão',   stats.accuracy == 100),
    ('⭐', 'Nv 5',            profile.level >= 5),
    ('👑', 'Rei dos Piratas', profile.level >= 9),
    ('💎', 'Diamante',        profile.league == 'diamond' || profile.league == 'master'),
    ('🔒', 'Lendário',        profile.level >= 10),
    ('🔒', 'Mestre',          profile.league == 'master'),
  ];

  @override
  Widget build(BuildContext context) {
    final achievements = _compute();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONQUISTAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .12)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: a.$3 ? AppColors.amber.withValues(alpha: 0.12) : AppColors.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: a.$3 ? AppColors.amber : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(a.$3 ? a.$1 : '🔒', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(a.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: a.$3 ? AppColors.amber : AppColors.textMuted)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _RecentHistory extends StatelessWidget {
  final List<RecentSession> sessions;
  const _RecentHistory({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTÓRICO RECENTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .12)),
        const SizedBox(height: 10),
        ...sessions.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(s.isVictory ? '🏆' : '💀', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.isVictory ? 'Vitória' : 'Game over',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${s.modeLabel} · ${s.questionsAnswered}/${s.questionsTotal}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('+${_fmtScore(s.score)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: s.isVictory ? AppColors.primaryPurple : AppColors.textSecondary)),
            ],
          ),
        )),
      ],
    );
  }
}

