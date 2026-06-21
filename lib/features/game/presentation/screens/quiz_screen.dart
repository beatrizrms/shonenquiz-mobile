import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/services/game_sound_controller.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/widgets/cat_avatar_view.dart';
import '../../../avatar/data/ability_slot_repository.dart';
import '../../../avatar/data/equipment_repository.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../shop/data/shop_repository.dart';
import '../../data/game_models.dart';
import '../../providers/game_provider.dart';
import 'boss_encounter_screen.dart';
import 'game_over_screen.dart';
import 'victory_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String mode;
  const QuizScreen({super.key, this.mode = 'classic'});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late GameSoundController _gameAudio;

  @override
  void initState() {
    super.initState();
    _gameAudio = GameSoundController(
      audio: ref.read(audioManagerProvider),
      sound: ref.read(soundServiceProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gameProvider.notifier).startSession(mode: widget.mode);
      _gameAudio.activate(widget.mode);
    });
  }

  @override
  void deactivate() {
    // deactivate() é chamado de cima para baixo (pai antes dos filhos),
    // antes de qualquer dispose(). Chamando detach() aqui garantimos que
    // _active = false antes que qualquer ConsumerStatefulWidget filho
    // fique defunct — evitando o assert '_lifecycleState != defunct'.
    ref.read(gameProvider.notifier).detach();
    super.deactivate();
  }

  @override
  void dispose() {
    _gameAudio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Selects estruturais — NÃO incluem secondsLeft para evitar rebuild a cada tick
    final phase    = ref.watch(gameProvider.select((s) => s.phase));
    final question = ref.watch(gameProvider.select((s) => s.currentQuestion));
    final error    = ref.watch(gameProvider.select((s) => s.error));
    final comboCombo = ref.watch(gameProvider.select((s) =>
        s.phase == GamePhase.answerReveal &&
        s.lastResult != null &&
        !s.isTimeOut &&
        s.lastResult!.isCorrect &&
        s.lastResult!.currentCombo >= 2
            ? s.lastResult!.currentCombo
            : 0));
    // Timer low sound + navegação para game over / vitória
    ref.listen(gameProvider, (prev, next) {
      if (!mounted) return;
      _gameAudio.onGameStateChanged(prev, next);
      if (prev?.phase == next.phase) return;
      if (next.phase == GamePhase.gameOver) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GameOverScreen(summary: next.summary, score: next.score, lives: next.lives)),
        );
      } else if (next.phase == GamePhase.victory) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => VictoryScreen(score: next.score, questionsAnswered: next.questionsAnswered, questionsTotal: next.questionsTotal, lastResult: next.lastResult, sessionId: next.sessionId)),
        );
      } else if (next.phase == GamePhase.bossEncounter && next.pendingBoss != null) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: true,
            barrierDismissible: false,
            pageBuilder: (_, __, ___) => BossEncounterScreen(boss: next.pendingBoss!),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });

    if (phase == GamePhase.loading || phase == GamePhase.idle) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      );
    }

    if (error != null && question == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😿', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('Erro ao carregar o jogo', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(gameProvider.notifier).startSession(mode: widget.mode),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (question == null) return const SizedBox.shrink();

    final activeBossEffect = ref.watch(gameProvider.select((s) => s.activeBoss?.effectType));
    final hasDistraction = activeBossEffect == 'screen_distraction';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            const _TopBar(),
            const _TimerBar(),
            const _CoinProgressPanel(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, _compact(context) ? 8 : 12, 14, _compact(context) ? 10 : 16),
                child: Column(
                  children: [
                    _QuestionCard(question: question),
                    const SizedBox(height: 16),
                    _OptionsGrid(
                      onSelect: (optionId) => ref.read(gameProvider.notifier).submitAnswer(optionId),
                      onNext: () {
                        _gameAudio.onButtonTap();
                        ref.read(gameProvider.notifier).advanceToNextQuestion();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (comboCombo >= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: _ComboBanner(combo: comboCombo, onPlay: _gameAudio.onCombo),
              ),
            const _BossEffectBanner(),
            const _AbilityBar(),
            const _BottomBar(),
          ],
        ),
      ),
          if (hasDistraction) const _ScreenDistractionOverlay(),
        ],
      ),
    );
  }
}

bool _compact(BuildContext context) => MediaQuery.of(context).size.height < 680;

Color _diffPhaseColor(String d) => switch (d) {
  'impossible' => const Color(0xFF9B30FF),
  'hard'       => AppColors.red,
  'medium'     => AppColors.amber,
  _            => AppColors.green,
};

String _diffPhaseLabel(String d) => switch (d) {
  'impossible' => '☠ Impossível',
  'hard'       => '🔥 Difícil',
  'medium'     => '⚡ Médio',
  _            => '✦ Fácil',
};

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerStatefulWidget {
  const _TopBar();

  @override
  ConsumerState<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<_TopBar> with TickerProviderStateMixin {
  late final List<AnimationController> _heartCtrls;
  late final List<Animation<double>> _heartScales;

  @override
  void initState() {
    super.initState();
    _heartCtrls = List.generate(3, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    ));
    _heartScales = _heartCtrls.map((c) => TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 75),
    ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
  }

  @override
  void dispose() {
    for (final c in _heartCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen detecta a mudança de vida e dispara a animação no coração perdido
    ref.listen(gameProvider.select((s) => s.lives), (prev, next) {
      if (prev != null && next < prev) {
        final idx = next; // índice 0-based do coração que acabou de ser perdido
        if (idx >= 0 && idx < 3) _heartCtrls[idx].forward(from: 0);
      }
    });

    final lives             = ref.watch(gameProvider.select((s) => s.lives));
    final questionsAnswered = ref.watch(gameProvider.select((s) => s.questionsAnswered));
    final questionsTotal    = ref.watch(gameProvider.select((s) => s.questionsTotal));
    final combo             = ref.watch(gameProvider.select((s) => s.combo));
    final difficulty        = ref.watch(gameProvider.select((s) => s.currentQuestion?.difficulty ?? 'easy'));

    final compact = _compact(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(14, compact ? 6 : 10, 14, compact ? 2 : 4),
      child: Row(
        children: [
          // Vidas — corações animados
          Row(
            children: List.generate(3, (i) {
              final active = i < lives;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: AnimatedBuilder(
                  animation: _heartCtrls[i],
                  builder: (_, __) => Transform.scale(
                    scale: _heartScales[i].value,
                    child: Icon(
                      active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: active ? AppColors.red : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          // Progresso + fase de dificuldade
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${questionsAnswered + 1} / $questionsTotal',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                _diffPhaseLabel(difficulty),
                style: TextStyle(fontSize: 9, color: _diffPhaseColor(difficulty), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          // Combo
          if (combo > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.green),
              ),
              child: Text('×$combo', style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
            )
          else
            const SizedBox(width: 40),
          // Fechar
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Abandonar partida?', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continuar', style: TextStyle(color: AppColors.primaryPurple))),
                    TextButton(
                      onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                      child: const Text('Sair', style: TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Timer bar ─────────────────────────────────────────────────────────────────

class _TimerBar extends ConsumerWidget {
  const _TimerBar();

  static int _estimatePoints(int secondsLeft, int combo) {
    const basePoints = 5;
    const timeLimitSec = 30;
    const maxSpeedMult = 3.0;
    final timeTakenMs = (timeLimitSec - secondsLeft) * 1000;
    final speedRatio = (1.0 - timeTakenMs / (timeLimitSec * 1000.0)).clamp(0.0, 1.0);
    final speedMult = 1.0 + speedRatio * (maxSpeedMult - 1.0);
    final comboMult = 1.0 + (combo * 0.1);
    return (basePoints * speedMult * comboMult).toInt();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondsLeft      = ref.watch(gameProvider.select((s) => s.secondsLeft));
    final combo            = ref.watch(gameProvider.select((s) => s.combo));
    final isReveal         = ref.watch(gameProvider.select((s) => s.phase == GamePhase.answerReveal));
    final pointMultiplier  = ref.watch(gameProvider.select((s) => s.pointMultiplier));
    final bossEffect       = ref.watch(gameProvider.select((s) => s.activeBoss?.effectType));
    final hideTimer        = bossEffect == 'hide_timer' && !isReveal;
    final progress = secondsLeft / 30.0;
    final isUrgent = secondsLeft <= 8;
    final color = isUrgent ? AppColors.red : AppColors.primaryPurple;
    final estimatedPts = _estimatePoints(secondsLeft, combo);
    final hasMultiplier = pointMultiplier > 1.0;

    // Formata o multiplicador: remove casas decimais desnecessárias (2.0 → "2", 1.5 → "1.5")
    final multiplierLabel = pointMultiplier == pointMultiplier.truncateToDouble()
        ? '×${pointMultiplier.toInt()}'
        : '×$pointMultiplier';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          hideTimer
              ? const SizedBox(width: 20, child: Text('?', style: TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center))
              : Text('$secondsLeft', style: TextStyle(fontSize: 10, color: isUrgent ? AppColors.red : AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: hideTimer
                  ? LinearProgressIndicator(value: null, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(AppColors.textMuted), minHeight: 5)
                  : LinearProgressIndicator(value: progress, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
            ),
          ),
          const SizedBox(width: 8),
          if (hasMultiplier && !isReveal)
            _MultiplierBadge(label: multiplierLabel)
          else
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isReveal ? AppColors.textMuted : (isUrgent ? AppColors.red : AppColors.amber),
              ),
              child: Text(isReveal ? '— pts' : '+$estimatedPts pts'),
            ),
        ],
      ),
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  const _MultiplierBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primaryPurple, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends ConsumerStatefulWidget {
  final Question question;
  const _QuestionCard({required this.question});

  @override
  ConsumerState<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<_QuestionCard> {
  // blur_question: alterna entre borrado e visível a cada 3s
  Timer? _blurTimer;
  bool _isBlurred = true;

  // hide_options_text controlado em _OptionsGrid; aqui só blur e scramble
  String? _lastEffect;

  @override
  void dispose() {
    _blurTimer?.cancel();
    super.dispose();
  }

  void _startBlur() {
    if (_blurTimer?.isActive ?? false) return;
    setState(() => _isBlurred = true);
    _blurTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) { _blurTimer?.cancel(); return; }
      setState(() => _isBlurred = !_isBlurred);
    });
  }

  void _stopBlur() {
    _blurTimer?.cancel();
    _blurTimer = null;
    _isBlurred = false;
  }

  static String _scramble(String text) {
    final rng = math.Random();
    return text.split(' ').map((word) {
      if (word.length <= 3) return word;
      final middle = word.substring(1, word.length - 1).split('');
      middle.shuffle(rng);
      return word[0] + middle.join() + word[word.length - 1];
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isHintRevealed = ref.watch(gameProvider.select((s) => s.isHintRevealed));
    final bossEffect     = ref.watch(gameProvider.select((s) => s.activeBoss?.effectType));
    final isReveal       = ref.watch(gameProvider.select((s) => s.phase == GamePhase.answerReveal));

    // Gerencia ciclo do blur
    if (bossEffect == 'blur_question' && !isReveal) {
      _startBlur();
    } else if (_lastEffect == 'blur_question') {
      _stopBlur();
    }
    _lastEffect = bossEffect;

    final isScramble = bossEffect == 'scramble_words' && !isReveal;
    final displayText = isScramble ? _scramble(widget.question.questionText) : widget.question.questionText;

    Widget questionText = Text(
      displayText,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500, height: 1.4),
    );

    if (bossEffect == 'blur_question' && _isBlurred && !isReveal) {
      questionText = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: questionText,
      );
    }

    if (bossEffect == 'extra_hard_question' && !isReveal) {
      questionText = Stack(
        children: [
          questionText,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CensorBarPainter(seed: widget.question.id.hashCode),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_compact(context) ? 12 : 16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _diffColor(widget.question.difficulty).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _diffLabel(widget.question.difficulty),
                  style: TextStyle(fontSize: 10, color: _diffColor(widget.question.difficulty), fontWeight: FontWeight.w500),
                ),
              ),
              if (widget.question.animeName.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    widget.question.animeName,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          questionText,
          if (isHintRevealed && widget.question.detailText != null && widget.question.detailText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('🔬', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(widget.question.detailText!, style: const TextStyle(fontSize: 12, color: AppColors.lightPurple, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _diffColor(String d) => switch (d) {
    'impossible' => const Color(0xFF9B30FF),
    'hard'       => AppColors.red,
    'medium'     => AppColors.amber,
    _            => AppColors.green,
  };

  String _diffLabel(String d) => switch (d) {
    'impossible' => 'Impossível',
    'hard'       => 'Difícil',
    'medium'     => 'Médio',
    _            => 'Fácil',
  };
}

// ── Screen distraction overlay ────────────────────────────────────────────────

class _ScreenDistractionOverlay extends StatefulWidget {
  const _ScreenDistractionOverlay();

  @override
  State<_ScreenDistractionOverlay> createState() => _ScreenDistractionOverlayState();
}

class _ScreenDistractionOverlayState extends State<_ScreenDistractionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _DistractionPainter(_ctrl.value),
        ),
      ),
    );
  }
}

class _DistractionPainter extends CustomPainter {
  final double t;
  _DistractionPainter(this.t);

  static const _balls = [
    // (pathX center, pathY center, radiusX, radiusY, phaseOffset, color, size)
    (0.50, 0.20, 0.30, 0.12, 0.00, Color(0xFFE24B4A), 70.0),
    (0.80, 0.50, 0.15, 0.30, 0.25, Color(0xFF534AB7), 55.0),
    (0.25, 0.70, 0.20, 0.15, 0.50, Color(0xFFE24B4A), 65.0),
    (0.55, 0.80, 0.35, 0.10, 0.75, Color(0xFF534AB7), 50.0),
    (0.15, 0.35, 0.10, 0.25, 0.12, Color(0xFFEF9F27), 45.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final (cx, cy, rx, ry, phase, color, r) in _balls) {
      final t2 = (t + phase) % 1.0;
      // Movimento elíptico em loop
      final x = size.width  * (cx + rx * math.sin(t2 * math.pi * 2));
      final y = size.height * (cy + ry * math.cos(t2 * math.pi * 2));
      // Opacidade pulsa entre 0.35 e 0.60
      final opacity = 0.35 + 0.25 * math.sin(t2 * math.pi * 2);
      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DistractionPainter old) => old.t != t;
}

// ── Censor bars overlay (extra_hard_question) ─────────────────────────────────

class _CensorBarPainter extends CustomPainter {
  final int seed;
  const _CensorBarPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..color = Colors.black;
    final barCount = 2 + rng.nextInt(2); // 2 ou 3 tarjas
    for (int i = 0; i < barCount; i++) {
      final widthFrac = 0.35 + rng.nextDouble() * 0.50; // 35%–85% da largura
      final leftFrac  = rng.nextDouble() * (1.0 - widthFrac);
      final topFrac   = 0.10 + rng.nextDouble() * 0.65; // espalha verticalmente
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * leftFrac,
          size.height * topFrac,
          size.width * widthFrac,
          20.0, // altura de ~1 linha de texto
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CensorBarPainter old) => old.seed != seed;
}

// ── Boss effect banner ────────────────────────────────────────────────────────

class _BossEffectBanner extends ConsumerWidget {
  const _BossEffectBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boss = ref.watch(gameProvider.select((s) => s.activeBoss));
    if (boss == null) return const SizedBox.shrink();

    final color = Color(boss.raridadeColor);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: boss.effectType == 'wrong_answer'
          ? Row(
              children: [
                const Text('🔀', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Responda ERRADO para vencer!',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${boss.villainName}: ${boss.powerName}',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Options ───────────────────────────────────────────────────────────────────

class _OptionsGrid extends ConsumerStatefulWidget {
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _OptionsGrid({
    required this.onSelect,
    required this.onNext,
  });

  @override
  ConsumerState<_OptionsGrid> createState() => _OptionsGridState();
}

class _OptionsGridState extends ConsumerState<_OptionsGrid> {
  String? _pendingId;
  String? _lastQuestionId;

  // shuffle_alternatives: reordena as opções periodicamente em loop
  Timer? _shuffleTimer;
  List<int> _shuffleOrder = [0, 1, 2, 3];
  int _shuffleGen = 0; // chave para AnimatedSwitcher

  // force_random: cicla o highlight entre as opções como uma roleta
  Timer? _forceRandomTimer;
  int _forceRandomHighlight = 0;

  // hide_options_text: alterna visibilidade das alternativas a cada 3s
  Timer? _hideOptionsTimer;
  bool _optionsVisible = true;

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _forceRandomTimer?.cancel();
    _hideOptionsTimer?.cancel();
    super.dispose();
  }

  void _startShuffle(int optionCount) {
    if (_shuffleTimer?.isActive ?? false) return;
    _shuffleOrder = List.generate(optionCount, (i) => i)..shuffle();
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) { _shuffleTimer?.cancel(); return; }
      setState(() {
        _shuffleOrder = List.generate(optionCount, (i) => i)..shuffle();
        _shuffleGen++;
      });
    });
  }

  void _stopShuffle() {
    _shuffleTimer?.cancel();
    _shuffleTimer = null;
  }

  void _startForceRandom(int optionCount) {
    if (_forceRandomTimer?.isActive ?? false) return;
    _forceRandomTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) { _forceRandomTimer?.cancel(); return; }
      setState(() => _forceRandomHighlight = (_forceRandomHighlight + 1) % optionCount);
    });
  }

  void _stopForceRandom() {
    _forceRandomTimer?.cancel();
    _forceRandomTimer = null;
  }

  void _startHideOptions() {
    if (_hideOptionsTimer?.isActive ?? false) return;
    setState(() => _optionsVisible = true);
    _hideOptionsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) { _hideOptionsTimer?.cancel(); return; }
      setState(() => _optionsVisible = !_optionsVisible);
    });
  }

  void _stopHideOptions() {
    _hideOptionsTimer?.cancel();
    _hideOptionsTimer = null;
    _optionsVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    final question        = ref.watch(gameProvider.select((s) => s.currentQuestion));
    final phase           = ref.watch(gameProvider.select((s) => s.phase));
    final lastResult      = ref.watch(gameProvider.select((s) => s.lastResult));
    final selectedOptionId = ref.watch(gameProvider.select((s) => s.selectedOptionId));
    final isTimeOut       = ref.watch(gameProvider.select((s) => s.isTimeOut));
    final eliminatedIds   = ref.watch(gameProvider.select((s) => s.eliminatedOptionIds));
    final revealedId      = ref.watch(gameProvider.select((s) => s.revealedCorrectOptionId));
    final activeBoss      = ref.watch(gameProvider.select((s) => s.activeBoss));

    // Reseta seleção pendente quando a pergunta muda
    if (question?.id != _lastQuestionId) {
      _lastQuestionId = question?.id;
      _pendingId = null;
      _stopShuffle();
      _stopForceRandom();
    }

    if (question == null) return const SizedBox.shrink();

    final result = lastResult;
    final isReveal = phase == GamePhase.answerReveal;
    final isForceRandom = activeBoss?.effectType == 'force_random' && !isReveal;
    final sound = ref.read(soundServiceProvider);

    // Aplica efeitos visuais do boss nas opções
    final bossEffect = activeBoss?.effectType;
    var displayedOptions = question.options.toList();
    if (bossEffect == 'shuffle_alternatives' && !isReveal) {
      // Inicia o timer de shuffle em loop; reordena segundo _shuffleOrder
      _startShuffle(displayedOptions.length);
      if (_shuffleOrder.length == displayedOptions.length) {
        displayedOptions = _shuffleOrder.map((i) => displayedOptions[i]).toList();
      }
    } else {
      _stopShuffle();
    }

    if (isForceRandom) {
      _startForceRandom(displayedOptions.length);
    } else {
      _stopForceRandom();
    }

    if (bossEffect == 'hide_options_text' && !isReveal) {
      _startHideOptions();
    } else {
      _stopHideOptions();
    }

    // fake_alternatives: adiciona marcador "correto" falso em 1 opção errada
    final fakeCorrectId = (bossEffect == 'fake_alternatives' && !isReveal)
        ? displayedOptions.where((o) => !o.id.contains(revealedId ?? '__')).firstOrNull?.id
        : null;

    // scramble_words: embaralha letras internas das alternativas
    final isScramble = bossEffect == 'scramble_words' && !isReveal;

    final effectiveRevealedId = revealedId;

    // wrong_answer: inversão — acertar é perder, errar é vencer
    final isLoseRound = bossEffect == 'wrong_answer';

    const labels = ['A', 'B', 'C', 'D'];

    // Apenas as 4 opções ficam dentro do AnimatedSwitcher para animação de shuffle
    final optionsOnly = Column(
      key: ValueKey(bossEffect == 'shuffle_alternatives' ? _shuffleGen : 0),
      children: [
        ...displayedOptions.asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          final isPending = !isReveal && _pendingId == opt.id;
          final isForceHighlight = isForceRandom && i == _forceRandomHighlight;
          final isSelected = !isTimeOut && selectedOptionId == opt.id;
          final isCorrect = result?.correctOptionId == opt.id;

          final hasResult = isReveal && result != null;

          final isEliminated = !isReveal && eliminatedIds.contains(opt.id);
          final isRevealed   = !isReveal && (effectiveRevealedId == opt.id || fakeCorrectId == opt.id);

          Color borderColor = AppColors.border;
          Color bgColor = AppColors.surface;
          Color textColor = AppColors.textPrimary;

          if (isEliminated) {
            bgColor = AppColors.surface;
            borderColor = AppColors.border;
            textColor = AppColors.textMuted;
          } else if (isRevealed) {
            borderColor = AppColors.primaryPurple;
            bgColor = AppColors.primaryPurple.withValues(alpha: 0.12);
            textColor = AppColors.lightPurple;
          } else if (hasResult && !isTimeOut) {
            if (isLoseRound) {
              // Invertido: selecionar errado = vitória (verde); selecionar correto = derrota (vermelho)
              if (isSelected && !isCorrect) {
                borderColor = AppColors.green;
                bgColor = AppColors.green.withValues(alpha: 0.12);
                textColor = AppColors.green;
              } else if (isSelected && isCorrect) {
                borderColor = AppColors.red;
                bgColor = AppColors.red.withValues(alpha: 0.10);
                textColor = AppColors.red;
              } else if (isCorrect) {
                // Marca a "correta real" como armadilha
                borderColor = AppColors.red.withValues(alpha: 0.5);
                bgColor = AppColors.red.withValues(alpha: 0.06);
                textColor = AppColors.textSecondary;
              }
            } else {
              if (isSelected && result!.isCorrect) {
                borderColor = AppColors.green;
                bgColor = AppColors.green.withValues(alpha: 0.12);
                textColor = AppColors.green;
              } else if (isSelected && !result!.isCorrect) {
                borderColor = AppColors.red;
                bgColor = AppColors.red.withValues(alpha: 0.10);
                textColor = AppColors.red;
              }
            }
          } else if (isReveal && isSelected) {
            // aguardando backend ou timeout — mostra âmbar
            borderColor = AppColors.amber;
            bgColor = AppColors.amber.withValues(alpha: 0.10);
            textColor = AppColors.amber;
          } else if (isPending) {
            borderColor = AppColors.amber;
            bgColor = AppColors.amber.withValues(alpha: 0.10);
            textColor = AppColors.amber;
          } else if (isForceHighlight) {
            borderColor = AppColors.red;
            bgColor = AppColors.red.withValues(alpha: 0.12);
            textColor = AppColors.textPrimary;
          }

          final badgeColor = isEliminated
              ? AppColors.textMuted
              : isRevealed
                  ? AppColors.primaryPurple
                  : (hasResult && !isTimeOut && isSelected && result!.isCorrect)
                      ? AppColors.green
                      : (hasResult && !isTimeOut && isSelected && !result!.isCorrect)
                          ? AppColors.red
                          : (isReveal && isSelected) || isPending
                              ? AppColors.amber
                              : AppColors.surfaceElevated;

          return GestureDetector(
            onTap: (isReveal || isEliminated || isPending)
                ? null
                : () {
                    sound.play(GameSound.click);
                    setState(() => _pendingId = opt.id);
                  },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: _compact(context) ? 10 : 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: (hasResult && !isTimeOut && isSelected) || (isReveal && isSelected) || isPending ? Colors.white : AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _optionsVisible || isReveal
                        ? Text(
                            isScramble ? _QuestionCardState._scramble(opt.optionText) : opt.optionText,
                            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w400),
                          )
                        : const SizedBox(height: 16),
                  ),
                  if (isEliminated) const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                  if (isRevealed) const Icon(Icons.auto_awesome_rounded, color: AppColors.lightPurple, size: 16),
                  if (hasResult && !isTimeOut && !isLoseRound && isSelected && result!.isCorrect) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                  if (hasResult && !isTimeOut && !isLoseRound && isSelected && !result!.isCorrect) const Icon(Icons.cancel_rounded, color: AppColors.red, size: 18),
                  // wrong_answer: ícones invertidos
                  if (hasResult && !isTimeOut && isLoseRound && isSelected && !isCorrect) const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
                  if (hasResult && !isTimeOut && isLoseRound && isSelected && isCorrect) const Icon(Icons.cancel_rounded, color: AppColors.red, size: 18),
                  if (hasResult && !isTimeOut && isLoseRound && !isSelected && isCorrect) const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 16),
                ],
              ),
            ),
          );
        }),
      ],
    );

    return Column(
      children: [
        // force_random: roleta visual — jogador ainda pode escolher qualquer opção
        if (isForceRandom)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withOpacity(0.6)),
            ),
            child: const Text(
              '🎲 Sua mente foi controlada — você ainda pode resistir!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w600),
            ),
          ),
        // shuffle_alternatives: anima a reordenação com crossfade rápido
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: optionsOnly,
        ),
        // Botão confirmar — aparece após 1ª seleção, antes de submeter
        if (!isReveal && _pendingId != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final id = _pendingId!;
                setState(() => _pendingId = null);
                widget.onSelect(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Confirmar →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
        // Botão próxima após reveal
        if (isReveal && result != null && result.isActive) ...[
          const SizedBox(height: 8),
          isTimeOut ? const _TimeOutBanner() : _ResultBanner(
            result: result,
            onPlay: () => sound.play(result.isCorrect ? GameSound.correct : GameSound.wrong),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Próxima →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeOutBanner extends StatelessWidget {
  const _TimeOutBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber),
      ),
      child: const Row(
        children: [
          Text('⏰', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text('Tempo esgotado!', style: TextStyle(fontSize: 13, color: AppColors.amber, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatefulWidget {
  final AnswerResult result;
  final VoidCallback onPlay;
  const _ResultBanner({required this.result, required this.onPlay});

  @override
  State<_ResultBanner> createState() => _ResultBannerState();
}

class _ResultBannerState extends State<_ResultBanner> {
  @override
  void initState() {
    super.initState();
    widget.onPlay();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: result.isCorrect ? AppColors.green.withValues(alpha: 0.10) : AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: result.isCorrect ? AppColors.green : AppColors.red),
      ),
      child: Row(
        children: [
          Text(result.isCorrect ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.isCorrect ? 'Correto! +${result.pointsEarned} pts' : 'Errou!',
              style: TextStyle(fontSize: 13, color: result.isCorrect ? AppColors.green : AppColors.red, fontWeight: FontWeight.w500),
            ),
          ),
          if (result.isCorrect && result.currentCombo >= 2)
            Text('×${result.currentCombo} combo', style: const TextStyle(fontSize: 11, color: AppColors.green)),
        ],
      ),
    );
  }
}

// ── Coin progress panel ───────────────────────────────────────────────────────

class _CoinProgressPanel extends ConsumerWidget {
  const _CoinProgressPanel();

  static const _percents = [0, 2, 4, 6, 9, 13, 18, 24, 31, 39, 48, 58, 69, 80, 90, 100];
  static const _safeZones = {5, 10};
  static const _maxCoins = 500;

  int _coins(int stage) => (_maxCoins * _percents[stage.clamp(0, 15)] / 100).toInt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinStage = ref.watch(gameProvider.select((s) => s.coinStage));
    // Mostra janela de 5 estágios ao redor do atual (ou mais no início/fim)
    final start = (coinStage - 2).clamp(0, 11);
    final end = (start + 4).clamp(4, 15);
    final stages = List.generate(end - start + 1, (i) => start + i);

    final compact = _compact(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 5 : 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Moedas atuais
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Suas moedas', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              Text(
                '${_coins(coinStage)} 🪙',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Escada de estágios
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stages.map((s) {
                final isCurrent = s == coinStage;
                final isPast = s < coinStage;
                final isSafe = _safeZones.contains(s);
                final isNext = s == coinStage + 1;

                Color bg = Colors.transparent;
                Color textColor = AppColors.textMuted;
                if (isCurrent) {
                  bg = AppColors.amber.withValues(alpha: 0.15);
                  textColor = AppColors.amber;
                } else if (isNext) {
                  textColor = AppColors.textSecondary;
                } else if (isPast) {
                  textColor = AppColors.green.withValues(alpha: 0.6);
                }

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent ? Border.all(color: AppColors.amber.withValues(alpha: 0.5)) : null,
                    ),
                    child: Column(
                      children: [
                        if (isSafe)
                          const Text('🛡️', style: TextStyle(fontSize: 8))
                        else
                          const SizedBox(height: 10),
                        Text(
                          '${_coins(s)}',
                          style: TextStyle(fontSize: 9, color: textColor, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Próxima recompensa
          if (coinStage < 15) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Próxima', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                Text(
                  '${_coins(coinStage + 1)} 🪙',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Combo banner ──────────────────────────────────────────────────────────────

class _ComboBanner extends StatefulWidget {
  final int combo;
  final VoidCallback onPlay;
  const _ComboBanner({required this.combo, required this.onPlay});

  @override
  State<_ComboBanner> createState() => _ComboBannerState();
}

class _ComboBannerState extends State<_ComboBanner> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _haloCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _fade  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn));

    _haloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    // Aparece e toca áudio juntos, 600ms após o som de acerto
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _visible = true);
      _entryCtrl.forward();
      _haloCtrl.forward();
      widget.onPlay();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _haloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final prev = widget.combo - 1;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Halo em ondas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _haloCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _HaloPainter(progress: _haloCtrl.value, color: AppColors.amber),
                ),
              ),
            ),
            // Conteúdo do banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${prev}x', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.amber),
                  ),
                  Text('${widget.combo}x', style: const TextStyle(fontSize: 16, color: AppColors.amber, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  const Text('COMBO', style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                  const SizedBox(width: 6),
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HaloPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 3 ondas desfasadas em 1/3 cada
    for (int i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      final spread = p * 22.0;
      final opacity = (1.0 - p) * 0.55;
      if (opacity <= 0.01) continue;
      paint.color = color.withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-spread, -spread, size.width + spread * 2, size.height + spread * 2),
          Radius.circular(12 + spread),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.progress != progress;
}

// ── Ability bar ───────────────────────────────────────────────────────────────

class _AbilityBar extends ConsumerWidget {
  const _AbilityBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync   = ref.watch(abilitySlotsProvider);
    final setsAsync    = ref.watch(abilitySetsProvider);
    final phase        = ref.watch(gameProvider.select((s) => s.phase));
    final slotCooldowns = ref.watch(gameProvider.select((s) => s.slotCooldowns));

    final slots = slotsAsync.valueOrNull ?? [];
    final sets  = { for (final s in (setsAsync.valueOrNull ?? [])) s.itemRef: s };

    final isActive   = phase == GamePhase.question;
    final bossEffect = ref.watch(gameProvider.select((s) => s.activeBoss?.effectType));
    final abilitiesBlocked = bossEffect == 'cancel_active_help';
    final compact = _compact(context);

    // Mostra sempre 4 slots (índice 0–3)
    final slotWidgets = List.generate(4, (i) {
      final slot     = slots.length > i ? slots[i] : null;
      final equipped = slot?.setRef != null ? sets[slot!.setRef!] : null;
      final cooldown = slotCooldowns[i] ?? 0;
      final isOnCooldown = cooldown > 0;
      final locked   = slot == null || !slot.unlocked;
      final empty    = equipped == null;

      final emoji    = equipped?.abilityEmoji ?? equipped?.emoji ?? '⚡';
      final label    = equipped?.abilityName ?? equipped?.name ?? (locked ? 'Bloqueado' : 'Vazio');
      final helpType = equipped?.abilityType ??
          equipped?.itemRef.replaceFirst('set-', '').replaceAll('-', '_');
      final abilityCooldown = equipped?.abilityCooldown ?? 3;
      final disabled = !isActive || isOnCooldown || locked || empty || abilitiesBlocked;

      return Expanded(
        child: GestureDetector(
          onTap: disabled ? null : () {
            ref.read(soundServiceProvider).play(GameSound.helpUsed);
            ref.read(gameProvider.notifier).useHelp(i, helpType!, cooldown: abilityCooldown);
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: disabled ? 0.35 : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
              decoration: BoxDecoration(
                color: isOnCooldown ? AppColors.surface : (disabled ? AppColors.surface : AppColors.surfaceElevated),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: disabled ? AppColors.border : AppColors.border.withValues(alpha: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locked ? '🔒' : (empty ? '＋' : emoji),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  if (isOnCooldown)
                    Text(
                      '$cooldown',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 8,
                        color: disabled ? AppColors.textMuted : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    return Container(
      padding: EdgeInsets.fromLTRB(10, compact ? 3 : 6, 10, compact ? 3 : 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (abilitiesBlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚫', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(
                    'Habilidades bloqueadas pelo boss',
                    style: TextStyle(fontSize: 9, color: AppColors.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('⚡', style: TextStyle(fontSize: 12)),
              ),
              ...slotWidgets,
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final catName = ref.watch(catNameProvider).valueOrNull ?? '';
    final draft = ref.watch(avatarDraftProvider);
    final equipped = ref.watch(equippedItemsProvider).valueOrNull?.toList() ?? const [];
    final score = ref.watch(gameProvider.select((s) => s.score));

    return Container(
      padding: EdgeInsets.fromLTRB(14, _compact(context) ? 5 : 8, 14, _compact(context) ? 8 : 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CatAvatarView(
                  breed: draft.breed.isNotEmpty ? draft.breed : 'tabby-brown',
                  eyeColor: draft.eyeColor.isNotEmpty ? draft.eyeColor : 'blue',
                  background: draft.background,
                  equipped: equipped,
                  size: 38,
                ),
              ),
              if (profile != null)
                Positioned(
                  bottom: -3, right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                    child: Text('Nv ${profile.level}',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  catName.isNotEmpty ? catName : (profile?.username ?? ''),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile?.leagueLabel ?? '',
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '$score pts',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightPurple),
          ),
        ],
      ),
    );
  }
}
