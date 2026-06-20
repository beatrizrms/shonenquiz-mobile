import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cdn_image.dart';
import '../../avatar/data/ability_slot_repository.dart';
import '../../shop/data/ability_set.dart';
import '../../shop/data/shop_repository.dart';

String _setName(String setRef) =>
    setRef.startsWith('set-') ? setRef.substring(4) : setRef;

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(abilitySlotsProvider);
      ref.invalidate(abilitySetsProvider);
      ref.invalidate(ownedItemsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(abilitySlotsProvider);
    final setsAsync = ref.watch(abilitySetsProvider);
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? const <String>{};

    final isLoading = slotsAsync.isLoading || setsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventário', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text('Habilidades e acessórios', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(abilitySlotsProvider);
                    ref.invalidate(abilitySetsProvider);
                    ref.invalidate(ownedItemsProvider);
                    await Future.wait([
                      ref.read(abilitySlotsProvider.future).then((_) {}, onError: (_) {}),
                      ref.read(abilitySetsProvider.future).then((_) {}, onError: (_) {}),
                      ref.read(ownedItemsProvider.future).then((_) {}, onError: (_) {}),
                    ]);
                  },
                  color: AppColors.primaryPurple,
                  backgroundColor: AppColors.surface,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    children: [
                      // ── Slots de habilidade ───────────────────────────────
                      slotsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (slots) {
                          final equipped = slots.where((s) => s.setRef != null).length;
                          return _SlotsSection(
                            slots: slots,
                            sets: setsAsync.valueOrNull ?? [],
                            equippedCount: equipped,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Sets / Habilidades ────────────────────────────────
                      setsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (sets) {
                          final slots = slotsAsync.valueOrNull ?? [];
                          final withProgress = sets.where((s) => s.ownedCount > 0).toList();
                          final locked = sets.where((s) => s.ownedCount == 0).toList();

                          return _SetsSection(
                            sets: withProgress,
                            locked: locked,
                            slots: slots,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Acessórios adquiridos ─────────────────────────────
                      setsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                        data: (sets) => _AccessoriesSection(sets: sets, owned: owned),
                      ),
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

// ── Slots ─────────────────────────────────────────────────────────────────────

class _SlotsSection extends ConsumerWidget {
  final List<AbilitySlot> slots;
  final List<AbilitySet> sets;
  final int equippedCount;
  const _SlotsSection({required this.slots, required this.sets, required this.equippedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Slots de Habilidade',
          trailing: '$equippedCount / ${slots.length} equipadas',
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: slots.map((s) {
            final set = s.setRef != null
                ? sets.firstWhere((x) => x.itemRef == s.setRef,
                    orElse: () => AbilitySet(itemRef: s.setRef!, name: s.setRef!, accessories: [], ownedCount: 0, totalCount: 0))
                : null;
            return _SlotCard(slot: s, set: set, onUnequip: () async {
              await ref.read(abilitySlotRepositoryProvider).unequip(s.slotIndex);
              ref.invalidate(abilitySlotsProvider);
            });
          }).toList(),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final AbilitySlot slot;
  final AbilitySet? set;
  final VoidCallback? onUnequip;
  const _SlotCard({required this.slot, required this.set, this.onUnequip});

  @override
  Widget build(BuildContext context) {
    final locked = !slot.unlocked;
    final isEmpty = slot.setRef == null;

    return GestureDetector(
      onTap: (set != null && onUnequip != null) ? () => _confirmUnequip(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: locked ? AppColors.background : (isEmpty ? AppColors.surface : AppColors.surfaceElevated),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: !isEmpty ? AppColors.selectionPurple : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: locked ? AppColors.background : (isEmpty ? AppColors.background : AppColors.primaryPurple.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: !isEmpty ? AppColors.selectionPurple : AppColors.border),
              ),
              child: locked
                  ? const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted)
                  : isEmpty
                      ? const Icon(Icons.add_rounded, size: 16, color: AppColors.textMuted)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CdnImage(
                            url: AppAssets.setImageUrl(_setName(set!.itemRef)),
                            fit: BoxFit.cover,
                            cacheWidth: 34,
                            errorWidget: Center(child: Text(set!.emoji ?? '🐱', style: const TextStyle(fontSize: 18))),
                          ),
                        ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locked ? 'Bloqueado' : (isEmpty ? 'Vazio' : set!.name),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: locked ? AppColors.textMuted : (isEmpty ? AppColors.textMuted : AppColors.textPrimary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (locked)
                    const Text('Desbloqueie\nao subir de nível', style: TextStyle(fontSize: 7, color: AppColors.textMuted, height: 1.3))
                  else if (!isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primaryPurple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                      child: const Text('Equipada', style: TextStyle(fontSize: 7, color: AppColors.lightPurple)),
                    )
                  else
                    Text('Slot ${slot.slotIndex + 1} livre', style: const TextStyle(fontSize: 7, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnequip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remover habilidade?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Text('Remover ${set!.name} do slot ${slot.slotIndex + 1}?', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); onUnequip?.call(); },
            child: const Text('Remover', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Sets ──────────────────────────────────────────────────────────────────────

class _SetsSection extends ConsumerWidget {
  final List<AbilitySet> sets;
  final List<AbilitySet> locked;
  final List<AbilitySlot> slots;
  const _SetsSection({required this.sets, required this.locked, required this.slots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Habilidades', trailing: null),
        const SizedBox(height: 4),
        const Text(
          'Complete o set de acessórios de um personagem para desbloquear a habilidade.',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        if (sets.isEmpty)
          const _EmptyState(label: 'Nenhuma habilidade em progresso')
        else
          ...sets.map((s) => _SetProgressCard(set: s, slots: slots)),

        if (locked.isNotEmpty) _LockedSetsHint(sets: locked),
      ],
    );
  }
}

class _SetProgressCard extends ConsumerWidget {
  final AbilitySet set;
  final List<AbilitySlot> slots;
  const _SetProgressCard({required this.set, required this.slots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = set.totalCount > 0 ? set.ownedCount / set.totalCount : 0.0;
    final isComplete = set.ownedCount == set.totalCount && set.totalCount > 0;
    final equippedSlot = slots.firstWhere(
      (s) => s.setRef == set.itemRef,
      orElse: () => AbilitySlot(slotIndex: -1, setRef: null, unlocked: false),
    );
    final isEquipped = equippedSlot.slotIndex >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEquipped ? const Color(0xFF0E1A10) : (isComplete ? AppColors.surfaceElevated : AppColors.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEquipped ? AppColors.success : (isComplete ? AppColors.selectionPurple : AppColors.border)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40, height: 40,
              child: CdnImage(
                url: AppAssets.setImageUrl(_setName(set.itemRef)),
                fit: BoxFit.cover,
                cacheWidth: 40,
                errorWidget: Center(child: Text(set.emoji ?? '🐱', style: const TextStyle(fontSize: 22))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(set.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    Text(
                      '${set.ownedCount}/${set.totalCount}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isComplete ? AppColors.success : AppColors.lightPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEquipped ? AppColors.success : (isComplete ? AppColors.selectionPurple : AppColors.primaryPurple),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF0E1A10), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.success)),
              child: const Text('Equipado', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success)),
            )
          else if (isComplete)
            GestureDetector(
              onTap: () => _showSlotPicker(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(8)),
                child: const Text('Equipar', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            )
          else
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  Future<void> _showSlotPicker(BuildContext context, WidgetRef ref) async {
    final available = slots.where((s) => s.unlocked && s.setRef == null).toList();
    if (available.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum slot disponível.'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (available.length == 1) {
      await _equip(context, ref, available.first.slotIndex);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _SlotPickerSheet(
        slots: available,
        onPick: (slotIndex) async {
          Navigator.pop(ctx);
          await _equip(context, ref, slotIndex);
        },
      ),
    );
  }

  Future<void> _equip(BuildContext context, WidgetRef ref, int slotIndex) async {
    try {
      await ref.read(abilitySlotRepositoryProvider).equip(slotIndex, set.itemRef);
      ref.invalidate(abilitySlotsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao equipar.'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _SlotPickerSheet extends StatelessWidget {
  final List<AbilitySlot> slots;
  final void Function(int) onPick;
  const _SlotPickerSheet({required this.slots, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          const Text('Escolha um slot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...slots.map((s) => GestureDetector(
            onTap: () => onPick(s.slotIndex),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${s.slotIndex + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightPurple)))),
                const SizedBox(width: 12),
                Text('Slot ${s.slotIndex + 1} — vazio', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

class _LockedSetsHint extends StatelessWidget {
  final List<AbilitySet> sets;
  const _LockedSetsHint({required this.sets});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(11), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${sets.length} habilidades bloqueadas', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: sets.map((s) => Opacity(
              opacity: 0.45,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.emoji ?? '🐱', style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(s.name, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ]),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Acessórios ────────────────────────────────────────────────────────────────

class _AccessoriesSection extends StatelessWidget {
  final List<AbilitySet> sets;
  final Set<String> owned;
  const _AccessoriesSection({required this.sets, required this.owned});

  @override
  Widget build(BuildContext context) {
    // Coleta acessórios que o usuário possui, sem duplicatas
    final seen = <String>{};
    final items = <(AccessoryItem, AbilitySet)>[];
    for (final s in sets) {
      for (final a in s.accessories) {
        if (owned.contains(a.itemRef) && seen.add(a.itemRef)) {
          items.add((a, s));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Acessórios', trailing: '${items.length} itens'),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const _EmptyState(label: 'Nenhum acessório ainda')
        else
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: items.map((pair) {
              final (acc, set) = pair;
              return _AccessoryCard(accessory: acc, setName: set.name);
            }).toList(),
          ),
      ],
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  final AccessoryItem accessory;
  final String setName;
  const _AccessoryCard({required this.accessory, required this.setName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(accessory.emoji ?? '🎀', style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(accessory.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.border)),
            child: Text('Set: $setName', style: const TextStyle(fontSize: 8, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF0E1A10), borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.success.withValues(alpha: 0.4))),
            child: const Text('Comprado', style: TextStyle(fontSize: 8, color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers visuais ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ),
    );
  }
}
