import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cdn_image.dart';
import '../../shop/data/ability_set.dart';
import '../../shop/data/shop_repository.dart';
import '../data/ability_slot_repository.dart';

String _setName(String setRef) =>
    setRef.startsWith('set-') ? setRef.substring(4) : setRef;

class EquipmentTab extends ConsumerWidget {
  const EquipmentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(abilitySetsProvider);
    final slotsAsync = ref.watch(abilitySlotsProvider);
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? const <String>{};

    return setsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Falha ao carregar habilidades',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => ref.invalidate(abilitySetsProvider),
              child: const Text('Tentar novamente')),
        ]),
      ),
      data: (sets) {
        final ownedSets = sets.where((s) => s.ownedCount > 0).toList();

        final seen = <String>{};
        final avulsos = <AccessoryItem>[];
        for (final s in sets) {
          for (final a in s.accessories) {
            if (owned.contains(a.itemRef) && seen.add(a.itemRef)) avulsos.add(a);
          }
        }

        final slots = slotsAsync.valueOrNull ?? [];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ── Faixa de slots ──────────────────────────────────────
            _SlotsRow(slots: slots, sets: sets),
            const SizedBox(height: 20),

            if (ownedSets.isEmpty && avulsos.isEmpty)
              const _EmptyState()
            else ...[
              if (ownedSets.isNotEmpty) ...[
                const _SectionDivider('INVENTÁRIO'),
                ...ownedSets.map((s) => _SetCard(set: s, owned: owned, slots: slots)),
              ],
              if (avulsos.isNotEmpty) ...[
                const SizedBox(height: 6),
                const _SectionDivider('ITENS AVULSOS'),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Itens que você possui. Complete um conjunto para poder equipá-lo.',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: avulsos.map((a) => _ItemCard(item: a)).toList(),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

// ── Faixa de 4 slots ─────────────────────────────────────────────────────────

class _SlotsRow extends ConsumerWidget {
  final List<AbilitySlot> slots;
  final List<AbilitySet> sets;
  const _SlotsRow({required this.slots, required this.sets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SLOTS DE HABILIDADE',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: .5),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) {
            final slot = slots.firstWhere(
              (s) => s.slotIndex == i,
              orElse: () => AbilitySlot(slotIndex: i, setRef: null, unlocked: false),
            );
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                child: _SlotTile(slot: slot, sets: sets),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Slots 2, 3 e 4 são desbloqueados ao subir de nível',
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SlotTile extends ConsumerWidget {
  final AbilitySlot slot;
  final List<AbilitySet> sets;
  const _SlotTile({required this.slot, required this.sets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final set = slot.setRef != null
        ? sets.firstWhere((s) => s.itemRef == slot.setRef,
            orElse: () => _placeholder(slot.setRef!))
        : null;

    final locked = !slot.unlocked;

    return GestureDetector(
      onTap: locked || set == null
          ? null
          : () => _confirmUnequip(context, ref, slot.slotIndex),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: locked
              ? AppColors.background
              : (set != null ? AppColors.surfaceElevated : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? AppColors.border
                : (set != null ? AppColors.selectionPurple : AppColors.border),
            width: set != null && !locked ? 1.5 : 1,
          ),
        ),
        child: locked
            ? _lockedContent(slot.slotIndex)
            : set != null
                ? _equippedContent(set)
                : _emptyContent(slot.slotIndex),
      ),
    );
  }

  Widget _lockedContent(int index) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔒', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text('Slot ${index + 1}',
              style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
        ],
      );

  Widget _emptyContent(int index) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline_rounded,
              size: 18, color: AppColors.textMuted),
          const SizedBox(height: 2),
          Text('Slot ${index + 1}',
              style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
        ],
      );

  Widget _equippedContent(AbilitySet set) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CdnImage(
                url: AppAssets.setImageUrl(_setName(set.itemRef)),
                fit: BoxFit.cover,
                cacheWidth: 32,
                errorWidget: Center(
                    child: Text(set.emoji ?? '🐱',
                        style: const TextStyle(fontSize: 18))),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              set.name,
              style:
                  const TextStyle(fontSize: 7, color: AppColors.lightPurple),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );

  Future<void> _confirmUnequip(
      BuildContext context, WidgetRef ref, int slotIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remover habilidade?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(abilitySlotRepositoryProvider).unequip(slotIndex);
    ref.invalidate(abilitySlotsProvider);
  }

  AbilitySet _placeholder(String setRef) => AbilitySet(
        itemRef: setRef,
        name: setRef,
        accessories: [],
        ownedCount: 0,
        totalCount: 0,
      );
}

// ── Card de conjunto ─────────────────────────────────────────────────────────

class _SetCard extends ConsumerWidget {
  final AbilitySet set;
  final Set<String> owned;
  final List<AbilitySlot> slots;
  const _SetCard({required this.set, required this.owned, required this.slots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedCount =
        set.accessories.where((a) => owned.contains(a.itemRef)).length;
    final total = set.accessories.length;
    final isComplete = total > 0 && ownedCount == total;
    final equippedSlot = slots.firstWhere(
        (s) => s.setRef == set.itemRef,
        orElse: () => AbilitySlot(slotIndex: -1, setRef: null, unlocked: false));
    final isEquipped = equippedSlot.slotIndex >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isEquipped ? AppColors.success : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 38,
                height: 38,
                child: CdnImage(
                  url: AppAssets.setImageUrl(_setName(set.itemRef)),
                  fit: BoxFit.cover,
                  cacheWidth: 38,
                  errorWidget: Center(
                      child: Text(set.emoji ?? '🐱',
                          style: const TextStyle(fontSize: 22))),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(set.name,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ),
            Text('$ownedCount/$total',
                style: TextStyle(
                    fontSize: 10,
                    color: isComplete
                        ? AppColors.success
                        : AppColors.lightPurple)),
          ]),

          if (set.description != null && set.description!.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Efeito',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(set.description!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textPrimary)),
                  ]),
            ),
          ],

          const SizedBox(height: 9),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: set.accessories.map((a) {
              final has = owned.contains(a.itemRef);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: has
                      ? const Color(0xFF0E1A10)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: has ? AppColors.success : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (has) ...[
                    const Icon(Icons.check, size: 10, color: AppColors.success),
                    const SizedBox(width: 3)
                  ],
                  Text(a.name,
                      style: TextStyle(
                          fontSize: 9,
                          color: has
                              ? AppColors.success
                              : AppColors.textSecondary)),
                ]),
              );
            }).toList(),
          ),

          const SizedBox(height: 9),
          if (isComplete)
            GestureDetector(
              onTap: isEquipped
                  ? () => _unequip(context, ref, equippedSlot.slotIndex)
                  : () => _showSlotPicker(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEquipped
                      ? const Color(0xFF0E1A10)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isEquipped
                          ? AppColors.success
                          : AppColors.selectionPurple),
                ),
                child: Text(
                  isEquipped
                      ? '✓ Equipado no slot ${equippedSlot.slotIndex + 1} · remover'
                      : 'Equipar habilidade',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isEquipped
                          ? AppColors.success
                          : AppColors.lightPurple),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '🔒 Complete o conjunto para equipar ($ownedCount/$total)',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showSlotPicker(BuildContext context, WidgetRef ref) async {
    final availableSlots =
        slots.where((s) => s.unlocked && s.setRef == null).toList();
    if (availableSlots.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum slot disponível. Remova uma habilidade ou desbloqueie mais slots.'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (availableSlots.length == 1 && context.mounted) {
      await _equip(context, ref, availableSlots.first.slotIndex);
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _SlotPickerSheet(
        slots: availableSlots,
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
          const SnackBar(
              content: Text('Erro ao equipar habilidade'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _unequip(BuildContext context, WidgetRef ref, int slotIndex) async {
    try {
      await ref.read(abilitySlotRepositoryProvider).unequip(slotIndex);
      ref.invalidate(abilitySlotsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao remover habilidade'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Bottom sheet — seleção de slot ────────────────────────────────────────────

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
          Center(
            child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 16),
          const Text('Escolha um slot',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Selecione em qual slot equipar esta habilidade',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...slots.map((s) => GestureDetector(
                onTap: () => onPick(s.slotIndex),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text('${s.slotIndex + 1}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lightPurple)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Slot ${s.slotIndex + 1} — vazio',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppColors.textMuted),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Item avulso ───────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final AccessoryItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji ?? '🎀',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 3),
          Text(item.name,
              style: const TextStyle(
                  fontSize: 8, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Helpers visuais ───────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: .1)),
        const SizedBox(width: 6),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('🛍️', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('Você ainda não tem habilidades',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Adquira conjuntos na Loja para vê-los aqui',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
