import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../data/anime_model.dart';
import '../data/onboarding_repository.dart';
import '../providers/onboarding_provider.dart';

const _categoryLabels = {
  'shonen':        'SHONEN',
  'seinen':        'SEINEN / CLÁSSICOS',
  'isekai':        'ISEKAI',
  'mecha':         'MECHA / SCI-FI',
  'slice_of_life': 'SLICE OF LIFE',
};

class AnimeSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final bool isEditing;
  const AnimeSelectionScreen({super.key, required this.onNext, this.isEditing = false});

  @override
  ConsumerState<AnimeSelectionScreen> createState() => _AnimeSelectionScreenState();
}

class _AnimeSelectionScreenState extends ConsumerState<AnimeSelectionScreen> {
  final _searchController = TextEditingController();
  final _expandedCategories = <String>{};
  String _search = '';
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadSavedAnimes();
  }

  Future<void> _loadSavedAnimes() async {
    setState(() => _loading = true);
    try {
      final saved = await ref.read(onboardingRepositoryProvider).fetchUserAnimes();
      if (mounted) {
        ref.read(selectedAnimesProvider.notifier).state = saved.map((a) => a.id).toSet();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final selected = ref.read(selectedAnimesProvider);
    setState(() => _saving = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveAnimePreferences(selected.toList());
      widget.onNext();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar animes'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animesAsync = ref.watch(allAnimesProvider);
    final selected   = ref.watch(selectedAnimesProvider);

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
                    const Text('Meus animes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              )
            else
              _StepHeader(current: 3, total: 4, label: 'SEUS ANIMES'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                  : animesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Falha ao carregar animes', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(allAnimesProvider),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
                data: (animes) {
                  final allAnimes = animes.toList();

                  final filtered = _search.isEmpty
                      ? allAnimes
                      : allAnimes.where((a) => a.name.toLowerCase().contains(_search.toLowerCase())).toList();

                  final byCategory = <String, List<AnimeModel>>{};
                  for (final a in filtered) {
                    byCategory.putIfAbsent(a.category, () => []).add(a);
                  }

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          children: [
                            _InfoCard(),
                            const SizedBox(height: 12),
                            _SearchBar(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _search = v),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      ..._categoryLabels.entries.map((entry) {
                        final items = byCategory[entry.key] ?? [];
                        if (items.isEmpty) return const SizedBox.shrink();
                        final selectedCount = items.where((a) => selected.contains(a.id)).length;
                        final isExpanded = _expandedCategories.contains(entry.key);
                        return _CategorySection(
                          label: entry.value,
                          animes: items,
                          selected: selected,
                          selectedCount: selectedCount,
                          total: items.length,
                          isExpanded: isExpanded,
                          onToggleExpand: () => setState(() {
                            if (isExpanded) {
                              _expandedCategories.remove(entry.key);
                            } else {
                              _expandedCategories.add(entry.key);
                            }
                          }),
                          onToggleAnime: (id) {
                            final next = Set<String>.from(selected);
                            if (next.contains(id)) {
                              next.remove(id);
                            } else {
                              next.add(id);
                            }
                            ref.read(selectedAnimesProvider.notifier).state = next;
                          },
                        );
                      }),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        selected: selected,
        isEditing: widget.isEditing,
        isSaving: _saving,
        onNext: widget.isEditing ? _save : widget.onNext,
      ),
    );
  }
}

// ── Step header ────────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int current;
  final int total;
  final String label;
  const _StepHeader({required this.current, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Text(
            'TELA $current DE $total — $label',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: .12),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(total, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < current ? AppColors.primaryPurple : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Info card ──────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.network(AppAssets.logoUrl, width: 48, height: 48, fit: BoxFit.contain),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('O que você curte?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Só aparecem perguntas dos animes\nque você conhece', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar anime...',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPurple)),
      ),
    );
  }
}

// ── Category section ───────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  final String label;
  final List<AnimeModel> animes;
  final Set<String> selected;
  final int selectedCount;
  final int total;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final void Function(String) onToggleAnime;

  const _CategorySection({
    required this.label, required this.animes, required this.selected,
    required this.selectedCount, required this.total, required this.isExpanded,
    required this.onToggleExpand, required this.onToggleAnime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: .08)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selectedCount > 0 ? AppColors.primaryPurple : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: selectedCount > 0 ? AppColors.primaryPurple : AppColors.border),
                  ),
                  child: Text(
                    '$selectedCount / $total',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selectedCount > 0 ? Colors.white : AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted, size: 18,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: animes.map((a) => _AnimePill(
                name: a.name,
                isSelected: selected.contains(a.id),
                onTap: () => onToggleAnime(a.id),
              )).toList(),
            ),
          ),
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ── Anime pill ─────────────────────────────────────────────────
class _AnimePill extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimePill({required this.name, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isSelected ? AppColors.selectionPurple : AppColors.border),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.lightPurple : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────
class _BottomBar extends ConsumerWidget {
  final Set<String> selected;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onNext;
  const _BottomBar({required this.selected, required this.isEditing, required this.isSaving, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canProceed   = selected.length >= 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                canProceed ? 'Selecionados' : 'Escolha pelo menos 3 animes',
                style: TextStyle(fontSize: 12, color: canProceed ? AppColors.textSecondary : AppColors.amber),
              ),
              Text(
                '${selected.length} animes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: canProceed ? AppColors.success : AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
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
        ],
      ),
    );
  }
}
