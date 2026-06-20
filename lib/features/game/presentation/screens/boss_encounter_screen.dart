import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/sound_service.dart';
import '../../data/game_models.dart';
import '../../providers/game_provider.dart';

class BossEncounterScreen extends ConsumerStatefulWidget {
  final BossEncounter boss;
  const BossEncounterScreen({super.key, required this.boss});

  @override
  ConsumerState<BossEncounterScreen> createState() => _BossEncounterScreenState();
}

class _BossEncounterScreenState extends ConsumerState<BossEncounterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.5, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _controller.forward();
    ref.read(soundServiceProvider).play(GameSound.boss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _raridadeColor => Color(widget.boss.raridadeColor);

  String get _effectLabel {
    return switch (widget.boss.effectType) {
      'wrong_answer'        => '🔀 Responda ERRADO para vencer — a alternativa certa é a armadilha!',
      'screen_distraction'  => '👁️ Distorção visual na tela',
      'cancel_active_help'  => '🚫 Cancela ajudas ativas',
      'fake_alternatives'   => '🎭 Cria ilusões de resposta correta',
      'speed_timer'         => '⚡ Acelera o cronômetro',
      'force_random'        => '🎲 Controla sua mente — a roleta destaca uma opção, mas você ainda pode resistir',
      'time_penalty'        => '⏳ Reduz o tempo restante em 10 segundos',
      'shuffle_alternatives' => '🌀 Embaralha as alternativas continuamente',
      'extra_hard_question' => '💀 Substitui a pergunta por uma impossível',
      'hide_timer'          => '⏱️ O tempo some — você não sabe quanto resta',
      'blur_question'       => '🌫️ Sua visão turva — a pergunta revela aos poucos',
      'scramble_words'      => '🔡 As palavras foram embaralhadas — decifre para responder',
      'hide_options_text'   => '👻 As alternativas somem e voltam em loop — memorize!',
      _                     => widget.boss.effectType,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Fecha automaticamente quando confirmBossAndContinue avança para question
    ref.listen(gameProvider.select((s) => s.phase), (prev, next) {
      if (next == GamePhase.question && mounted) {
        Navigator.of(context).pop();
      }
    });

    final boss = widget.boss;
    final color = _raridadeColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Header
              Text(
                '⚠️ BOSS APARECEU',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // ── Card do boss
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Raridade badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(
                          boss.raridadeLabel.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nome do vilão
                      Text(
                        boss.villainName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),

                      // Nome do poder
                      Text(
                        boss.powerName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color),
                      ),
                      const SizedBox(height: 16),

                      // Separador
                      Divider(color: AppColors.border),
                      const SizedBox(height: 12),

                      // Efeito
                      Text(
                        _effectLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),

                      // Duração
                      if (boss.effectDuration > 1)
                        Text(
                          'Dura ${boss.effectDuration} perguntas',
                          style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Botão de enfrentar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ref.read(gameProvider.notifier).confirmBossAndContinue(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enfrentar!',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
