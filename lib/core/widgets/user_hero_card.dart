import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/avatar/data/equipment_repository.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/profile/data/user_profile.dart';
import 'cat_avatar_view.dart';

class UserHeroCard extends ConsumerWidget {
  final UserProfile profile;
  final String? catName;

  const UserHeroCard({super.key, required this.profile, this.catName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpPct = (profile.xp / profile.xpToNextLevel).clamp(0.0, 1.0);
    final displayName = (catName != null && catName!.isNotEmpty) ? catName! : profile.username;

    final draft = ref.watch(avatarDraftProvider);
    final equipped = ref.watch(equippedItemsProvider).valueOrNull?.toList() ?? const [];

    return Container(
      padding: const EdgeInsets.all(14),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CatAvatarView(
                      breed: draft.breed.isNotEmpty ? draft.breed : 'tabby-brown',
                      eyeColor: draft.eyeColor.isNotEmpty ? draft.eyeColor : 'blue',
                      background: draft.background,
                      equipped: equipped,
                      size: 58,
                    ),
                  ),
                  Positioned(
                    bottom: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: Text('Nv ${profile.level}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.levelTitle} · ${profile.leagueLabel}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryPurple, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(3, (i) {
                          final active = i < profile.lives.clamp(0, 3);
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: active ? AppColors.red : AppColors.textMuted,
                              size: 16,
                            ),
                          );
                        }),
                        if (profile.lives < 3) ...[
                          const SizedBox(width: 5),
                          const Text('Recarga em 12h', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CurrencyPill(emoji: '🪙', value: profile.kokas, color: AppColors.amber),
                  const SizedBox(height: 5),
                  _CurrencyPill(emoji: '💎', value: profile.gems, color: AppColors.lightPurple),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('XP', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('${profile.xp} / ${profile.xpToNextLevel}',
                  style: const TextStyle(fontSize: 10, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: xpPct,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  const _CurrencyPill({required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text('$value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
