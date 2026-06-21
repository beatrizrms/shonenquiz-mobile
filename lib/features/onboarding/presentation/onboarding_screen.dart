import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cat_avatar_view.dart';
import '../../auth/providers/auth_provider.dart';
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

class _StepIndicator extends ConsumerWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
        child: Row(
          children: [
            ...List.generate(3, (i) {
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await ref.read(authStatusProvider.notifier).logout();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Sair',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends ConsumerWidget {
  final bool saving;
  final VoidCallback onFinish;
  const _WelcomeStep({required this.saving, required this.onFinish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(avatarDraftProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final avatarSize = screenHeight < 700 ? 140.0 : 180.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              CatAvatarView(
                breed: draft.breed,
                eyeColor: draft.eyeColor,
                background: draft.background,
                size: avatarSize,
              ),
              SizedBox(height: screenHeight < 700 ? 16 : 24),
              Text(
                draft.catName.isNotEmpty ? draft.catName : 'Tudo pronto!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
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
