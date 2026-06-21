import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/user_hero_card.dart';
import '../../game/data/game_models.dart';
import '../../game/presentation/screens/quiz_screen.dart';
import '../../game/providers/game_mode_configs_provider.dart';
import '../../menu/presentation/menu_bottom_sheet.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/daily_reward_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catName = ref.watch(catNameProvider).valueOrNull ?? '';
    final profile = ref.watch(userProfileProvider).valueOrNull;

    ref.listen(dailyLoginProvider, (_, next) {
      next.whenData((result) {
        if (!result.claimed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Login diário!', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                    Text('+${result.nekocoinsClaimed} Nekocoins', style: const TextStyle(color: AppColors.amber, fontSize: 12)),
                  ],
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.invalidate(userProfileProvider);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(catNameProvider);
            await Future.wait([
              ref.read(userProfileProvider.future).then((_) {}, onError: (_) {}),
              ref.read(catNameProvider.future).then((_) {}, onError: (_) {}),
            ]);
          },
          color: AppColors.primaryPurple,
          backgroundColor: AppColors.surface,
          child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // ── Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Olá,', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        '${catName.isNotEmpty ? catName : (profile?.username ?? 'Jogador')} 👋',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (profile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1408),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFF854F0B)),
                      ),
                      child: Text('🥇 #42', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.amber)),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const MenuBottomSheet(),
                    ),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.menu_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Hero card
            if (profile != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                child: UserHeroCard(profile: profile!, catName: catName.isNotEmpty ? catName : null),
              ),

            // ── Desafio do dia
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1408),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFF854F0B)),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Desafio do Dia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.amber)),
                        Text('Modo Sobrevivência · Só One Piece', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1408),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF854F0B)),
                    ),
                    child: const Text('+500 🪙', style: TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            // ── Jogar agora
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuizScreen(mode: 'classic')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    elevation: 0,
                  ),
                  child: const Text('⚡ Jogar agora', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),

            // ── Modos de jogo 2×2
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: _ModeGrid(),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ModeGrid extends ConsumerWidget {
  const _ModeGrid();

  String _subtitle(List<GameModeConfig> configs, String mode, String fallback) {
    final c = configs.forMode(mode);
    if (c == null) return fallback;
    return '${c.questionsTotal} perguntas · ${c.timerSeconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(gameModeConfigsProvider).valueOrNull ?? [];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ModeCard(emoji: '🎯', title: 'Clássico',       subtitle: _subtitle(configs, 'classic',  '20 perguntas'), mode: 'classic'),
        _ModeCard(emoji: '⏱️', title: 'Contrarrelógio', subtitle: _subtitle(configs, 'timed',    '60s por pergunta'), mode: null),
        _ModeCard(emoji: '💀', title: 'Sobrevivência',  subtitle: _subtitle(configs, 'survival', 'Sem errar'), mode: null),
        _ModeCard(emoji: '⚔️', title: 'Torneio',        subtitle: 'Versus amigos', mode: null),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? mode;
  const _ModeCard({required this.emoji, required this.title, required this.subtitle, this.mode});

  @override
  Widget build(BuildContext context) {
    final available = mode != null;
    return GestureDetector(
      onTap: available
          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(mode: mode!)))
          : null,
      child: Opacity(
        opacity: available ? 1.0 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              if (!available)
                const Text('Em breve', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
