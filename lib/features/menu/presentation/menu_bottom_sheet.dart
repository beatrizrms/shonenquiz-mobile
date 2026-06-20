import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/presentation/anime_selection_screen.dart';
import '../../onboarding/presentation/avatar_creation_screen.dart';
import '../../profile/providers/profile_provider.dart';

class MenuBottomSheet extends ConsumerWidget {
  const MenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final catName = ref.watch(catNameProvider).valueOrNull ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: profileAsync.when(
              loading: () => const SizedBox(height: 20),
              error: (_, _) => const SizedBox.shrink(),
              data: (p) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${catName.isNotEmpty ? catName : p.username} 👋',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Text('🏅 ', style: TextStyle(fontSize: 12)),
                            Text(p.leagueLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const Text(' · Nv ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('${p.level}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        const Text('🪙', style: TextStyle(fontSize: 13, color: AppColors.amber, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Text('${p.kokas}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('💎', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text('${p.gems}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightPurple)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          _MenuItem(
            item: (Icons.person_outline, 'Perfil', 'Stats, conquistas e histórico', false),
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            item: (Icons.catching_pokemon, 'Meu gato', 'Customizar avatar e cosplays', false),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AvatarCreationScreen(isEditing: true, onNext: () => Navigator.pop(context)),
                ),
              );
            },
          ),
          _MenuItem(
            item: (Icons.star_outline, 'Meus animes', '', false),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeSelectionScreen(isEditing: true, onNext: () => Navigator.pop(context)),
                ),
              );
            },
          ),
          _MenuItem(
            item: (Icons.notifications_none, 'Notificações', 'Desafios e alertas de ranking', false),
            onTap: () => Navigator.pop(context),
          ),
          _MenuItem(
            item: (Icons.settings_outlined, 'Configurações', 'Som, idioma, conta', false),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: AppColors.border, height: 1),
          _MenuItem(
            item: (Icons.logout, 'Sair', '', true),
            onTap: () => _confirmLogout(context, ref),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sair', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Tem certeza que deseja sair?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await ref.read(authStatusProvider.notifier).logout();
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final (IconData, String, String, bool) item;
  final VoidCallback? onTap;

  const _MenuItem({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, isDanger) = item;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          children: [
            Container(
              width: 38, height: 38, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDanger ? AppColors.error.withValues(alpha: 0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDanger ? AppColors.error.withValues(alpha: 0.4) : AppColors.border),
              ),
              child: Icon(icon, size: 18, color: isDanger ? AppColors.error : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDanger ? AppColors.error : AppColors.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (!isDanger)
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
