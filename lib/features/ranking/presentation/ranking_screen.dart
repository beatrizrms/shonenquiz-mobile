import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/data/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/ranking_repository.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalAsync = ref.watch(globalRankingProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final season = globalAsync.valueOrNull?.season;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ranking', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text(
                        season?.name ?? 'Carregando…',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (season != null) _SeasonTimer(season: season),
                ],
              ),
            ),

            // ── Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.lightPurple,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 10),
                tabs: const [Tab(text: 'Global'), Tab(text: 'Amigos'), Tab(text: 'Liga')],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _GlobalTab(profile: profile),
                  const _ComingSoon('Adicione amigos para ver o ranking aqui', '👥'),
                  _LeagueTab(profile: profile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Season timer ──────────────────────────────────────────────────────────────

class _SeasonTimer extends StatelessWidget {
  final RankingSeason season;
  const _SeasonTimer({required this.season});

  @override
  Widget build(BuildContext context) {
    final remaining = season.remaining;
    final days = remaining.inDays;
    final label = days > 0 ? '${days}d restantes' : 'Encerrando hoje';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }
}

// ── Global tab ────────────────────────────────────────────────────────────────

class _GlobalTab extends ConsumerWidget {
  final UserProfile? profile;
  const _GlobalTab({this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(globalRankingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(globalRankingProvider);
        await ref.read(globalRankingProvider.future).then((_) {}, onError: (_) {});
      },
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(globalRankingProvider)),
        data: (result) => result.isEmpty
            ? _EmptyRanking(season: result.season)
            : _RankingList(result: result),
      ),
    );
  }
}

// ── League tab ────────────────────────────────────────────────────────────────

class _LeagueTab extends ConsumerStatefulWidget {
  final UserProfile? profile;
  const _LeagueTab({this.profile});

  @override
  ConsumerState<_LeagueTab> createState() => _LeagueTabState();
}

class _LeagueTabState extends ConsumerState<_LeagueTab> {
  String _league = 'bronze';

  static const _leagues = [
    ('bronze',  '🥉', 'Bronze'),
    ('silver',  '🥈', 'Prata'),
    ('gold',    '🥇', 'Ouro'),
    ('diamond', '💎', 'Diamante'),
    ('master',  '⚔️', 'Mestre'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) _league = widget.profile!.league;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leagueRankingProvider(_league));

    return Column(
      children: [
        // Liga selector
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: _leagues.map((l) {
              final (key, emoji, label) = l;
              final selected = _league == key;
              return GestureDetector(
                onTap: () => setState(() => _league = key),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryPurple : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: selected ? AppColors.primaryPurple : AppColors.border),
                  ),
                  child: Text('$emoji $label',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leagueRankingProvider(_league));
              await ref.read(leagueRankingProvider(_league).future).then((_) {}, onError: (_) {});
            },
            color: AppColors.primaryPurple,
            backgroundColor: AppColors.surface,
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
              error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(leagueRankingProvider(_league))),
              data: (result) => result.isEmpty
                  ? _EmptyRanking(season: result.season)
                  : _RankingList(result: result),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Ranking list (pódio + lista) ──────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  final RankingResult result;
  const _RankingList({required this.result});

  @override
  Widget build(BuildContext context) {
    final top3 = result.entries.take(3).toList();
    final rest = result.entries.skip(3).toList();
    final me = result.currentUserEntry;
    // Se o usuário atual não está no top visível, mostrar ao final fixo
    final meInList = result.entries.any((e) => e.isCurrentUser);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
      children: [
        if (top3.isNotEmpty) _Podium(top3: top3),
        const SizedBox(height: 12),
        ...rest.map((e) => _EntryRow(entry: e)),
        // Usuário atual fora do top — fixo no final
        if (!meInList && me != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: AppColors.border),
          ),
          _EntryRow(entry: me),
        ],
      ],
    );
  }
}

// ── Pódio ─────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<RankingEntry> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Garante ordem: 2º, 1º, 3º
    final ordered = [
      top3.length > 1 ? top3[1] : null,
      top3[0],
      top3.length > 2 ? top3[2] : null,
    ];
    final medals = ['🥈', '🥇', '🥉'];
    final heights = [55.0, 80.0, 40.0];

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final entry = ordered[i];
          if (entry == null) return const SizedBox(width: 88);
          final isFirst = i == 1;
          return SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (entry.isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(99)),
                    child: const Text('Você', style: TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                const SizedBox(height: 2),
                Text('🐱', style: TextStyle(fontSize: isFirst ? 28 : 22)),
                const SizedBox(height: 2),
                Text(entry.username,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                Text(
                  _fmt(entry.score),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lightPurple),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 72, height: heights[i],
                  decoration: BoxDecoration(
                    color: isFirst ? AppColors.surfaceElevated : AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    border: Border.all(color: isFirst ? AppColors.primaryPurple : AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(medals[i], style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _fmt(int score) {
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }
}

// ── Entry row ─────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  final RankingEntry entry;
  const _EntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: entry.isCurrentUser ? AppColors.primaryPurple : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${entry.position}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: entry.isCurrentUser ? AppColors.lightPurple : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const Text('🐱', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.username,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text('${entry.levelTitle} · Nv ${entry.level}',
                    style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(entry.score),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.lightPurple),
              ),
              if (entry.isCurrentUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.primaryPurple),
                  ),
                  child: const Text('Você', style: TextStyle(fontSize: 9, color: AppColors.lightPurple)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int score) {
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }
}

// ── Empty ranking (estado inicial sem dados) ──────────────────────────────────

class _EmptyRanking extends StatelessWidget {
  final RankingSeason? season;
  const _EmptyRanking({this.season});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        // Pódio vazio ilustrativo
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmptyBar(height: 55, medal: '🥈'),
              const SizedBox(width: 4),
              _EmptyBar(height: 80, medal: '🥇', isFirst: true),
              const SizedBox(width: 4),
              _EmptyBar(height: 40, medal: '🥉'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('🏆', style: TextStyle(fontSize: 40)),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Ranking ainda vazio',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            season != null
                ? 'Jogue na ${season!.name} para aparecer aqui.'
                : 'Jogue partidas para aparecer no ranking.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              _HowToItem(emoji: '🎮', text: 'Jogue partidas e acumule pontos'),
              SizedBox(height: 10),
              _HowToItem(emoji: '⚡', text: 'Responda rápido para multiplicar pontos'),
              SizedBox(height: 10),
              _HowToItem(emoji: '🔥', text: 'Mantenha combos para subir no ranking'),
              SizedBox(height: 10),
              _HowToItem(emoji: '🏅', text: 'Top 10% da temporada sobe de liga'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyBar extends StatelessWidget {
  final double height;
  final String medal;
  final bool isFirst;
  const _EmptyBar({required this.height, required this.medal, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('?', style: TextStyle(fontSize: isFirst ? 26 : 20, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          width: 72, height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(medal, style: TextStyle(fontSize: 16, color: AppColors.textMuted.withValues(alpha: 0.4))),
        ),
      ],
    );
  }
}

class _HowToItem extends StatelessWidget {
  final String emoji;
  final String text;
  const _HowToItem({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      ],
    );
  }
}

// ── Error + Coming soon ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😿', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text('Falha ao carregar ranking', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente', style: TextStyle(color: AppColors.primaryPurple))),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String message;
  final String emoji;
  const _ComingSoon(this.message, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
