import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/game_models.dart';

class GameOverScreen extends ConsumerWidget {
  final SessionSummary? summary;
  final int score;
  final int lives;

  const GameOverScreen({super.key, this.summary, required this.score, required this.lives});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0a0a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const Text('😿', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Game Over',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.red),
              ),
              const SizedBox(height: 8),
              const Text(
                'Suas vidas acabaram',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _StatRow('Pontuação', '$score pts', AppColors.lightPurple),
                    if (summary != null) ...[
                      const SizedBox(height: 12),
                      _StatRow('Acertos', '${summary!.correctCount} / ${summary!.questionsTotal}', AppColors.textPrimary),
                      const SizedBox(height: 12),
                      _StatRow('Maior combo', '×${summary!.maxCombo}', AppColors.amber),
                      const SizedBox(height: 12),
                      _StatRow('XP ganho', '+${summary!.xpEarned} XP', AppColors.green),
                      const SizedBox(height: 12),
                      _StatRow('Nekocoins', '+${summary!.nekocoinsEarned} 🪙', AppColors.amber),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Voltar para home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
