import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HelpsScreen extends StatelessWidget {
  const HelpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('AJUDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .15)),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    Text('Em construção...', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    SizedBox(height: 8),
                    Text('Fase 3 — Progressão e social', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
