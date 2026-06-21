import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/game_models.dart';
import '../../data/game_repository.dart';

class VictoryScreen extends ConsumerStatefulWidget {
  final int score;
  final int questionsAnswered;
  final int questionsTotal;
  final AnswerResult? lastResult;
  final String? sessionId;

  const VictoryScreen({
    super.key,
    required this.score,
    required this.questionsAnswered,
    required this.questionsTotal,
    this.lastResult,
    this.sessionId,
  });

  @override
  ConsumerState<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends ConsumerState<VictoryScreen>
    with TickerProviderStateMixin {
  List<SessionAchievement> _achievements = [];
  int _visibleCount = 0;

  // Animação de pulso no score
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  bool _scorePulsing = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadAndAnimate();
  }

  Future<void> _loadAndAnimate() async {
    if (widget.sessionId == null) return;
    try {
      final summary =
          await ref.read(gameRepositoryProvider).getSummary(widget.sessionId!);
      if (!mounted) return;
      setState(() => _achievements = summary.achievements);

      await Future.delayed(const Duration(milliseconds: 900));

      for (int i = 0; i < _achievements.length; i++) {
        if (!mounted) return;
        setState(() => _visibleCount = i + 1);

        // Pulsa o score 300ms após o card aparecer
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() => _scorePulsing = true);
        await _pulseCtrl.forward(from: 0);
        if (!mounted) return;
        setState(() => _scorePulsing = false);

        await Future.delayed(const Duration(milliseconds: 700));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xp = widget.lastResult?.xpEarned ?? 0;
    final coins = widget.lastResult?.nekocoinsEarned ?? 0;
    final combo = widget.lastResult?.currentCombo ?? 0;
    final dailyGem = widget.lastResult?.dailyWinGemEarned ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0a1a0e),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('🏆', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Vitória!',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você completou todas as perguntas',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Score animado
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseScale,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseScale.value,
                        child: Text(
                          '${widget.score}',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: _scorePulsing ? AppColors.amber : AppColors.green,
                          ),
                        ),
                      ),
                    ),
                    const Text('pontos',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recompensas base
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _RewardRow('XP ganho', '+$xp XP', AppColors.lightPurple),
                    const SizedBox(height: 10),
                    _RewardRow('Nekocoins', '+$coins 🪙', AppColors.amber),
                    const SizedBox(height: 10),
                    _RewardRow(
                        'Acertos',
                        '${widget.questionsAnswered} / ${widget.questionsTotal}',
                        AppColors.textPrimary),
                    if (combo >= 2) ...[
                      const SizedBox(height: 10),
                      _RewardRow('Maior combo', '×$combo 🔥', AppColors.green),
                    ],
                    if (dailyGem) ...[
                      const SizedBox(height: 10),
                      _RewardRow('Vitória diária', '+1 💎', AppColors.lightPurple),
                    ],
                  ],
                ),
              ),

              // Conquistas desbloqueadas
              if (_visibleCount > 0) ...[
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Conquistas',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(_visibleCount, (i) {
                  final a = _achievements[i];
                  return _AchievementCard(achievement: a);
                }),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Voltar para home',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Achievement card com animação de entrada ──────────────────────────────────

class _AchievementCard extends StatefulWidget {
  final SessionAchievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween(begin: 24.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _bonusText() {
    final a = widget.achievement;
    if (a.effectType == 'zero') return 'Score zerado';
    if (a.bonusApplied != null) {
      return '+${a.bonusApplied!.toStringAsFixed(0)} pts no ${a.bonusMetric}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.achievement.label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.amber,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _bonusText(),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.amber,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linha de recompensa ───────────────────────────────────────────────────────

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _RewardRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}
