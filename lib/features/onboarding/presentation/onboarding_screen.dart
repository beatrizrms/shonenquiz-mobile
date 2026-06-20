import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../data/onboarding_repository.dart';
import '../providers/onboarding_provider.dart';
import 'anime_selection_screen.dart';
import 'avatar_creation_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);
    try {
      final repo    = ref.read(onboardingRepositoryProvider);
      final selected = ref.read(selectedAnimesProvider).toList();
      final draft    = ref.read(avatarDraftProvider);

      await repo.saveAnimePreferences(selected);
      await repo.saveAvatar(
        catName:    draft.catName,
        breed:      draft.breed,
        eyeColor:   draft.eyeColor,
        accessory:  draft.accessory,
        background: draft.background,
      );

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _StepIndicator(currentStep: _step),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                AnimeSelectionScreen(onNext: () => setState(() => _step = 1)),
                AvatarCreationScreen(onNext: () => setState(() => _step = 2)),
                _WelcomeStep(saving: _saving, onFinish: _saveAndFinish),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: List.generate(3, (i) {
            final active = i <= currentStep;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryPurple : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final bool saving;
  final VoidCallback onFinish;
  const _WelcomeStep({required this.saving, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text('🐱', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              const Text('Tudo pronto!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              const Text(
                'Seu gato está pronto para a aventura.\nBoa sorte nas quests!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : onFinish,
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Começar!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
