import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Ícone de Kōka (硬貨) — moeda japonesa com furo central.
/// Usa o caractere Unicode 🪙 (BULLSEYE, U+25CE) em dourado.
class KokaIcon extends StatelessWidget {
  final double size;
  final Color color;
  const KokaIcon({super.key, this.size = 14, this.color = AppColors.amber});

  @override
  Widget build(BuildContext context) {
    return Text(
      '🪙',
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
  }
}

/// Label "🪙 1.200" para preços e saldos.
class KokaLabel extends StatelessWidget {
  final int value;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  const KokaLabel({
    super.key,
    required this.value,
    this.fontSize = 11,
    this.color = AppColors.amber,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '🪙 $value',
      style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
    );
  }
}
