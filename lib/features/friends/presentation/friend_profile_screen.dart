import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/friends_models.dart';
import '../data/friends_repository.dart';
import '../providers/friends_provider.dart';
import 'widgets/friend_avatar.dart';

String _fmtScore(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class FriendProfileScreen extends ConsumerWidget {
  final String userId;
  final String friendshipId;

  const FriendProfileScreen({super.key, required this.userId, required this.friendshipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: profileAsync.whenOrNull(data: (p) => Text(p.username, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        actions: [
          profileAsync.whenOrNull(
            data: (p) => _RemoveButton(friendshipId: friendshipId, onRemoved: () => Navigator.pop(context)),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Perfil não disponível', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.invalidate(friendProfileProvider(userId)), child: const Text('Tentar novamente')),
            ],
          ),
        ),
        data: (profile) => _ProfileContent(profile: profile),
      ),
    );
  }
}

class _RemoveButton extends ConsumerWidget {
  final String friendshipId;
  final VoidCallback onRemoved;
  const _RemoveButton({required this.friendshipId, required this.onRemoved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.person_remove_outlined, color: AppColors.red),
      tooltip: 'Remover amigo',
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Remover amigo?', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          content: const Text(
            'O histórico de partidas é mantido, mas você não poderá mais ver o perfil desta pessoa.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(friendsRepositoryProvider).removeFriend(friendshipId);
                ref.invalidate(friendsListProvider);
                onRemoved();
              },
              child: const Text('Remover', style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final FriendProfile profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(profile: profile),
        const SizedBox(height: 16),
        _StatsGrid(stats: profile.stats, profile: profile),
        const SizedBox(height: 20),
        _AchievementsSection(profile: profile),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final FriendProfile profile;
  const _HeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final xpPct = (profile.xp / (profile.level * 200)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FriendAvatar(size: 58, level: profile.level),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.username, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${profile.levelTitle} · ${profile.leagueLabel}',
                        style: const TextStyle(fontSize: 12, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(3, (i) {
                        final active = i < profile.lives.clamp(0, 3);
                        return Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(
                            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: active ? AppColors.red : AppColors.textMuted,
                            size: 14,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('XP', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('${profile.xp} / ${profile.level * 200}',
                  style: const TextStyle(fontSize: 10, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: xpPct,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final FriendStats stats;
  final FriendProfile profile;
  const _StatsGrid({required this.stats, required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${stats.totalSessions}', 'Partidas\njogadas'),
      ('${stats.accuracy}%', 'Precisão\ngeral'),
      ('🔥 ${stats.maxCombo}', 'Maior\nsequência'),
      (_fmtScore(stats.totalScore), 'Pontos\ntotais'),
      (profile.leagueLabel.split(' ').last, 'Liga\natual'),
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
  final FriendProfile profile;
  const _AchievementsSection({required this.profile});

  List<(String, String, bool)> _compute(FriendStats s) => [
    ('🔥', 'Combo ×10',       s.maxCombo >= 10),
    ('🎯', '100% precisão',   s.accuracy == 100),
    ('⭐', 'Nv 5',            profile.level >= 5),
    ('👑', 'Rei dos Piratas', profile.level >= 9),
    ('💎', 'Diamante',        profile.league == 'diamond' || profile.league == 'master'),
    ('🔒', 'Lendário',        profile.level >= 10),
  ];

  @override
  Widget build(BuildContext context) {
    final achievements = _compute(profile.stats);
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
                Text(a.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: a.$3 ? AppColors.amber : AppColors.textMuted)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}
