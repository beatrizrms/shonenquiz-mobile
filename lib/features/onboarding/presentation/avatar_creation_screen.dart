import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_catalog.dart';
import '../../../core/widgets/cat_avatar_view.dart';
import '../../../core/widgets/cdn_image.dart';
import '../../avatar/data/equipment_repository.dart';
import '../../shop/data/shop_repository.dart';
import '../data/onboarding_repository.dart';
import '../providers/onboarding_provider.dart';

class AvatarCreationScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final bool isEditing;
  const AvatarCreationScreen({super.key, required this.onNext, this.isEditing = false});

  @override
  ConsumerState<AvatarCreationScreen> createState() => _AvatarCreationScreenState();
}

class _AvatarCreationScreenState extends ConsumerState<AvatarCreationScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _loading = false;
  bool _precached = false;
  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadAvatar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Pré-carrega gatos + olhos + cenários no cache de disco para troca instantânea
    for (final b in avatarBreeds) {
      precacheImage(CachedNetworkImageProvider(AppAssets.catUrl(b.$3)), context);
    }
    precacheImage(CachedNetworkImageProvider(AppAssets.catUrl(avatarFallbackCatFile)), context);
    for (final e in avatarEyes) {
      precacheImage(CachedNetworkImageProvider(AppAssets.eyeUrl(eyeFileForColor(e.$1))), context);
    }
    for (final bg in avatarBackgrounds) {
      precacheImage(CachedNetworkImageProvider(AppAssets.backgroundUrl(bg.$4)), context);
    }
  }

  Future<void> _loadAvatar() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(onboardingRepositoryProvider).fetchAvatar();
      if (data != null && mounted) {
        // Prioriza o olho já salvo; só usa o padrão quando não há seleção.
        final savedEye = data['eyeColor'] as String?;
        final draft = AvatarDraft(
          catName:    data['catName'] as String? ?? '',
          breed:      data['breed'] as String? ?? 'tabby-brown',
          eyeColor:   (savedEye != null && savedEye.isNotEmpty) ? savedEye : avatarDefaultEye,
          accessory:  data['accessory'] as String?,
          background: data['background'] as String?,
        );
        ref.read(avatarDraftProvider.notifier).state = draft;
        _nameController.text = draft.catName;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = ref.read(avatarDraftProvider);
    setState(() => _saving = true);
    var saved = false;
    try {
      await ref.read(onboardingRepositoryProvider).saveAvatar(
        catName:    draft.catName,
        breed:      draft.breed,
        eyeColor:   draft.eyeColor,
        accessory:  draft.accessory,
        background: draft.background,
      );
      saved = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar avatar'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Navega só após o save bem-sucedido — fora do try, para um erro de
    // navegação não disparar o snackbar de "erro ao salvar".
    if (saved && mounted) {
      // ScaffoldMessenger do root sobrevive ao pop da tela de edição.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar salvo! 🐾'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(avatarDraftProvider);
    final equipped = ref.watch(equippedItemsProvider).valueOrNull ?? const <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isEditing)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Meu gato', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            if (!_loading) _FixedCatPanel(
              draft: draft,
              equipped: equipped.toList(),
              compact: false,
            ),
            Expanded(child: _caracteristicasContent(draft, equipped)),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
              canProceed: draft.catName.isNotEmpty,
              isEditing: widget.isEditing,
              isSaving: _saving,
              onNext: widget.isEditing ? _save : widget.onNext,
            ),
    );
  }

  Widget _caracteristicasContent(AvatarDraft draft, Set<String> equipped) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        if (!widget.isEditing) ...[
          const Text('Personalize seu avatar', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
        ],

        // Nome
        _SectionLabel('Nome do gato'),
        TextField(
          controller: _nameController,
          maxLength: 30,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Ex: Kuroneko', counterText: ''),
          onChanged: (v) => ref.read(avatarDraftProvider.notifier).update((s) => s.copyWith(catName: v)),
        ),
        const SizedBox(height: 20),

        _SectionLabel('Raça'),
        _BreedGrid(
          selected: draft.breed,
          onSelect: (v) => ref.read(avatarDraftProvider.notifier).update((s) => s.copyWith(breed: v)),
        ),
        const SizedBox(height: 20),

        _SectionLabel('Olhos'),
        _OptionGrid(
          options: avatarEyes.map((e) => (e.$1, e.$2, e.$3)).toList(),
          selected: draft.eyeColor,
          onSelect: (v) => ref.read(avatarDraftProvider.notifier).update((s) => s.copyWith(eyeColor: v)),
        ),
        const SizedBox(height: 20),

        _SectionLabel('Cenário'),
        _OptionGrid(
          options: [
            ('', 'Nenhum', '🚫'),
            ...avatarBackgrounds.map((b) => (b.$1, b.$2, b.$3)),
          ],
          selected: draft.background ?? '',
          onSelect: (v) => ref.read(avatarDraftProvider.notifier).update((s) => s.copyWith(background: v.isEmpty ? null : v)),
        ),
        const SizedBox(height: 20),

        // Aparência do personagem — carrossel dos sets que o usuário possui
        if (widget.isEditing) ...[
          _SectionLabel('Aparência do personagem'),
          _SetAppearanceCarousel(equippedItems: equipped.toList()),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

class _FixedCatPanel extends StatelessWidget {
  final AvatarDraft draft;
  final List<String> equipped;
  final bool compact;
  const _FixedCatPanel({required this.draft, this.equipped = const [], this.compact = false});

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.of(context).size.height * 0.40;
    final panelHeight = compact ? base * 0.40 : base;

    return Container(
      height: panelHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Gato grande — ocupa todo o espaço disponível do painel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxHeight < constraints.maxWidth
                      ? constraints.maxHeight
                      : constraints.maxWidth;
                  return Center(
                    child: GestureDetector(
                      onTap: () => showCatAvatarFullScreen(
                        context,
                        breed: draft.breed,
                        eyeColor: draft.eyeColor,
                        background: draft.background,
                        equipped: equipped,
                      ),
                      child: CatAvatarView(
                        breed: draft.breed,
                        eyeColor: draft.eyeColor,
                        background: draft.background,
                        equipped: equipped,
                        size: size,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedGrid extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _BreedGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: avatarBreeds.map((b) {
        final isSelected = b.$1 == selected;
        return GestureDetector(
          onTap: () => onSelect(b.$1),
          child: Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.selectionPurple : AppColors.border, width: isSelected ? 1.5 : 1),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  // Miniatura só com a raça (sem olho) — mais leve.
                  child: CatAvatarView(breed: b.$1, eyeColor: avatarDefaultEye, size: 56, showEyes: false),
                ),
                const SizedBox(height: 5),
                Text(
                  b.$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: .05)),
  );
}

class _OptionGrid extends StatelessWidget {
  final List<(String, String, String)> options;
  final String selected;
  final void Function(String) onSelect;

  const _OptionGrid({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o.$1 == selected;
        return GestureDetector(
          onTap: () => onSelect(o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColors.selectionPurple : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o.$3, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(o.$2, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.textPrimary : AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Carrossel de aparência dos sets equipados ─────────────────────────────────

class _SetAppearanceCarousel extends ConsumerWidget {
  final List<String> equippedItems;
  const _SetAppearanceCarousel({required this.equippedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(abilitySetsProvider);

    // Set visualmente ativo (o que está em user_equipped_items com prefixo set-)
    final activeSetRef = equippedItems.firstWhere(
      (r) => r.startsWith('set-'),
      orElse: () => '',
    );

    return setsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple, strokeWidth: 2)),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (sets) {
        final ownedSets = sets.where((s) => s.totalCount > 0 && s.ownedCount == s.totalCount).toList();

        if (ownedSets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(children: [
              Text('🐱', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Compre sets na Loja para personalizar a aparência do seu gato',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ]),
          );
        }

        // Opção "Nenhum" + todos os sets que o usuário possui
        final options = <(String, String, String?)>[
          ('', 'Nenhum', null),
          ...ownedSets.map((s) => (s.itemRef, s.name, s.emoji)),
        ];

        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (context, idx) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (ref_, label, emoji) = options[i];
              final isSelected = ref_.isEmpty
                  ? activeSetRef.isEmpty
                  : activeSetRef == ref_;
              final setRef = ref_.isNotEmpty
                  ? ref_.substring(4) // remove 'set-'
                  : null;

              return GestureDetector(
                onTap: isSelected
                    ? null
                    : () async {
                        final repo = ref.read(equipmentRepositoryProvider);
                        // Remove set anterior
                        if (activeSetRef.isNotEmpty) {
                          await repo.unequip(activeSetRef);
                        }
                        // Equipa o novo (se não for "Nenhum")
                        if (ref_.isNotEmpty) {
                          await repo.equip(ref_);
                        }
                        ref.invalidate(equippedItemsProvider);
                      },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.selectionPurple : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ref_.isEmpty)
                        const Text('🚫', style: TextStyle(fontSize: 26))
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: CdnImage(
                              url: AppAssets.setImageUrl(setRef!),
                              fit: BoxFit.cover,
                              cacheWidth: 48,
                              errorWidget: Center(
                                child: Text(emoji ?? '🐱',
                                    style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected
                              ? AppColors.lightPurple
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.selectionPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool canProceed;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onNext;
  const _BottomBar({required this.canProceed, required this.isEditing, required this.isSaving, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (canProceed && !isSaving) ? onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed ? AppColors.primaryPurple : AppColors.border,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
          child: isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'Salvar' : 'Continuar', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
