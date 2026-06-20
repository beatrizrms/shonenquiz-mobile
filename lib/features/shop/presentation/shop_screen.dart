import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../profile/data/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/ability_set.dart';
import '../data/shop_item.dart';
import '../data/shop_repository.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Text('Loja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const Spacer(),
                  if (profile != null) ...[
                    _CurrencyPill(emoji: '🪙', value: profile.kokas, bg: const Color(0xFF1A1408), border: const Color(0xFF854F0B), color: AppColors.amber),
                    const SizedBox(width: 5),
                    _CurrencyPill(emoji: '💎', value: profile.gems, bg: AppColors.surfaceElevated, border: AppColors.primaryPurple, color: AppColors.lightPurple),
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                      child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(6)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.lightPurple,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 10),
                tabs: const [
                  Tab(text: 'Novidades'),
                  Tab(text: 'Acessórios'),
                  Tab(text: 'Personagens'),
                  Tab(text: 'Moedas'),
                ],
              ),
            ),

            // ── Content
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _NovidadesTab(),
                  _AcessoriosTab(),
                  _HabilidadesTab(),
                  _MoedasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Purchase helper ───────────────────────────────────────────────────────────

Future<void> _doPurchase(
  BuildContext context,
  WidgetRef ref,
  String itemRef,
  String currency,
) async {
  try {
    await ref.read(shopRepositoryProvider).purchase(itemRef, currency);
    ref.invalidate(ownedItemsProvider);
    ref.invalidate(userProfileProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item adquirido! 🎉'), backgroundColor: AppColors.success, duration: Duration(seconds: 2)),
      );
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: AppColors.error, duration: const Duration(seconds: 3)),
      );
    }
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

Future<void> _refreshShop(WidgetRef ref, ProviderBase<Object?> itemsProvider) async {
  ref.invalidate(ownedItemsProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(itemsProvider);
  await Future.wait([
    ref.read(ownedItemsProvider.future).then((_) {}, onError: (_) {}),
    ref.read(userProfileProvider.future).then((_) {}, onError: (_) {}),
  ]);
}

List<Widget> _itemsGrid(List<ShopItem> items, Set<String> owned, WidgetRef ref, {Map<String, String> setNames = const {}}) {
  if (items.isEmpty) {
    return const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Nenhum item disponível', style: TextStyle(color: AppColors.textSecondary))))];
  }
  return [
    GridView.count(
      crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.78,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _ShopItemCard(
        item: item,
        isOwned: owned.contains(item.itemRef),
        ref: ref,
        setName: item.setRef != null ? setNames[item.setRef] : null,
      )).toList(),
    ),
  ];
}

class _NovidadesTab extends ConsumerStatefulWidget {
  const _NovidadesTab();

  @override
  ConsumerState<_NovidadesTab> createState() => _NovidadesTabState();
}

class _NovidadesTabState extends ConsumerState<_NovidadesTab> {
  // null = todos, 'accessory' = acessórios, 'ability_set' = sets
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? {};
    final itemsAsync = ref.watch(featuredItemsProvider);
    final setNames = {
      for (final s in ref.watch(abilitySetsProvider).valueOrNull ?? <AbilitySet>[]) s.itemRef: s.name,
    };

    return RefreshIndicator(
      onRefresh: () => _refreshShop(ref, featuredItemsProvider),
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF1A1030), borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.primaryPurple)),
            child: const Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Novidades da semana', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightPurple)),
                    Text('Itens em destaque por tempo limitado', style: TextStyle(fontSize: 10, color: AppColors.primaryPurple)),
                  ]),
                ),
              ],
            ),
          ),
          // ── Filtro
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              _FilterChip(label: 'Todos',      selected: _filter == null,           onTap: () => setState(() => _filter = null)),
              _FilterChip(label: 'Acessórios', selected: _filter == 'accessory',    onTap: () => setState(() => _filter = _filter == 'accessory'    ? null : 'accessory')),
              _FilterChip(label: 'Sets',       selected: _filter == 'ability_set',  onTap: () => setState(() => _filter = _filter == 'ability_set'  ? null : 'ability_set')),
            ]),
          ),

          ...itemsAsync.when(
            loading: () => const [Padding(padding: EdgeInsets.only(top: 30), child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)))],
            error: (e, _) => const [Padding(padding: EdgeInsets.only(top: 30), child: Center(child: Text('Falha ao carregar novidades', style: TextStyle(color: AppColors.textSecondary))))],
            data: (items) {
              final filtered = _filter == null ? items : items.where((i) => i.category == _filter).toList();
              return _itemsGrid(filtered, owned, ref, setNames: setNames);
            },
          ),
        ],
      ),
    );
  }
}

class _AcessoriosTab extends ConsumerStatefulWidget {
  const _AcessoriosTab();

  @override
  ConsumerState<_AcessoriosTab> createState() => _AcessoriosTabState();
}

class _AcessoriosTabState extends ConsumerState<_AcessoriosTab> {
  final _search = TextEditingController();
  String _query = '';
  String? _filterSet; // null = todos

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? {};
    final itemsAsync = ref.watch(accessoriesProvider);
    final setsAsync = ref.watch(abilitySetsProvider);

    // Monta lista de sets para o filtro
    final sets = setsAsync.valueOrNull ?? [];

    return RefreshIndicator(
      onRefresh: () => _refreshShop(ref, accessoriesProvider),
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          // ── Busca
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar acessório…',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _search.clear(); setState(() => _query = ''); },
                        child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple)),
              ),
            ),
          ),

          // ── Filtro por personagem
          if (sets.isNotEmpty) ...[
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'Todos', selected: _filterSet == null, onTap: () => setState(() => _filterSet = null)),
                  ...sets.map((s) => _FilterChip(
                    label: s.name,
                    selected: _filterSet == s.itemRef,
                    onTap: () => setState(() => _filterSet = _filterSet == s.itemRef ? null : s.itemRef),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Grid
          ...itemsAsync.when(
            loading: () => const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)))],
            error: (e, _) => const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Falha ao carregar acessórios', style: TextStyle(color: AppColors.textSecondary))))],
            data: (items) {
              var filtered = items.where((i) {
                final matchQuery = _query.isEmpty || i.name.toLowerCase().contains(_query);
                final matchSet = _filterSet == null || i.setRef == _filterSet;
                return matchQuery && matchSet;
              }).toList();

              // Resolve o nome do set de cada item para exibir no card
              final setNames = <String, String>{
                for (final s in sets) s.itemRef: s.name,
              };

              if (filtered.isEmpty) {
                return const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Nenhum acessório encontrado', style: TextStyle(color: AppColors.textSecondary))))];
              }
              return [
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.72,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: filtered.map((item) => _SmallAccessoryCard(
                    item: item,
                    isOwned: owned.contains(item.itemRef),
                    setName: item.setRef != null ? setNames[item.setRef] : null,
                    ref: ref,
                  )).toList(),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _HabilidadesTab extends ConsumerStatefulWidget {
  const _HabilidadesTab();

  @override
  ConsumerState<_HabilidadesTab> createState() => _HabilidadesTabState();
}

class _HabilidadesTabState extends ConsumerState<_HabilidadesTab> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(abilitySetsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownedItemsProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(abilitySetsProvider);
        await Future.wait([
          ref.read(ownedItemsProvider.future).then((_) {}, onError: (_) {}),
          ref.read(userProfileProvider.future).then((_) {}, onError: (_) {}),
          ref.read(abilitySetsProvider.future).then((_) {}, onError: (_) {}),
        ]);
      },
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          // ── Busca
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar personagem…',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _search.clear(); setState(() => _query = ''); },
                        child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryPurple)),
              ),
            ),
          ),

          ...setsAsync.when(
            loading: () => const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)))],
            error: (e, _) => const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Falha ao carregar personagens', style: TextStyle(color: AppColors.textSecondary))))],
            data: (sets) {
              final filtered = _query.isEmpty
                  ? sets
                  : sets.where((s) =>
                      s.name.toLowerCase().contains(_query) ||
                      (s.abilityName?.toLowerCase().contains(_query) ?? false)).toList();
              if (filtered.isEmpty) {
                return const [Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('Nenhum personagem encontrado', style: TextStyle(color: AppColors.textSecondary))))];
              }
              return filtered.map((set) => _AbilitySetCard(set: set)).toList();
            },
          ),
        ],
      ),
    );
  }
}

class _MoedasTab extends ConsumerWidget {
  const _MoedasTab();

  static const _packs = [
    _CoinPack(emoji: '🪙', title: '500 Kōka',   subtitle: 'Pacote iniciante', price: 'R\$ 4,99',  highlight: false, itemRef: 'pack-coins-500'),
    _CoinPack(emoji: '🪙', title: '1.500 Kōka', subtitle: '+20% bônus',      price: 'R\$ 12,99', highlight: false, itemRef: 'pack-coins-1500'),
    _CoinPack(emoji: '🪙', title: '5.000 Kōka', subtitle: '+50% bônus',      price: 'R\$ 34,99', highlight: true,  itemRef: 'pack-coins-5000'),
    _CoinPack(emoji: '💎', title: '30 Gemas',   subtitle: 'Pacote básico',   price: 'R\$ 9,99',  highlight: false, isGem: true, itemRef: 'pack-gems-30'),
    _CoinPack(emoji: '💎', title: '100 Gemas',  subtitle: '+25% bônus',      price: 'R\$ 24,99', highlight: true,  isGem: true, itemRef: 'pack-gems-100'),
    _CoinPack(emoji: '💎', title: '300 Gemas',  subtitle: '+60% bônus',      price: 'R\$ 59,99', highlight: false, isGem: true, itemRef: 'pack-gems-300'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        await ref.read(userProfileProvider.future).then((_) {}, onError: (_) {});
      },
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        children: [
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('KŌKA', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: .1, fontWeight: FontWeight.w600))),
          ..._packs.where((p) => !p.isGem).map((p) => _CoinPackCard(pack: p)),
          const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Text('GEMAS', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: .1, fontWeight: FontWeight.w600))),
          ..._packs.where((p) => p.isGem).map((p) => _CoinPackCard(pack: p)),
        ],
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _CoinPack {
  final String emoji;
  final String title;
  final String subtitle;
  final String price;
  final bool highlight;
  final bool isGem;
  final String itemRef;
  const _CoinPack({required this.emoji, required this.title, required this.subtitle, required this.price, required this.highlight, required this.itemRef, this.isGem = false});
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _canAfford(UserProfile profile, ShopItem item) {
  if (item.priceGems != null) return profile.gems >= item.priceGems!;
  if (item.priceCoins != null) return profile.kokas >= item.priceCoins!;
  return true;
}

// ── Shop item card ────────────────────────────────────────────────────────────

String _categoryLabel(String category) {
  switch (category) {
    case 'accessory':
      return 'Acessório';
    case 'eye_skin':
      return 'Skin de olhos';
    case 'cosplay':
      return 'Cosplay';
    default:
      return category;
  }
}

class _ShopItemCard extends StatefulWidget {
  final ShopItem item;
  final bool isOwned;
  final WidgetRef ref;
  final String? setName;
  const _ShopItemCard({required this.item, required this.isOwned, required this.ref, this.setName});

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard> {
  bool _loading = false;

  String get _priceLabel {
    if (widget.item.priceGems != null) return '💎 ${widget.item.priceGems}';
    if (widget.item.priceCoins != null) return '🪙 ${widget.item.priceCoins}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isOwned = widget.isOwned;
    final isPremium = widget.item.isGemOnly;
    final borderColor = isOwned ? AppColors.success : isPremium ? AppColors.primaryPurple : AppColors.border;
    final bgColor = isOwned ? const Color(0xFF0E1A10) : isPremium ? AppColors.premiumBg : AppColors.surface;

    final profile = widget.ref.watch(userProfileProvider).valueOrNull;
    final canAfford = profile == null || _canAfford(profile, widget.item);

    return Opacity(
      opacity: isOwned ? 0.55 : 1.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50, child: Center(child: Text(widget.item.emoji ?? '🎁', style: const TextStyle(fontSize: 30)))),
                const SizedBox(height: 2),
                Text(_categoryLabel(widget.item.category), style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                if (widget.setName != null)
                  Text(widget.setName!, style: const TextStyle(fontSize: 9, color: AppColors.lightPurple), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(widget.item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (isOwned)
                  const Text('Adquirido', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500))
                else if (!_loading)
                  Opacity(
                    opacity: canAfford ? 1.0 : 0.4,
                    child: GestureDetector(
                      onTap: canAfford ? () async {
                        setState(() => _loading = true);
                        try {
                          final currency = widget.item.priceGems != null ? 'gems' : 'coins';
                          await _doPurchase(context, widget.ref, widget.item.itemRef, currency);
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPremium ? AppColors.primaryPurple : AppColors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_priceLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPremium ? Colors.white : const Color(0xFF1A0A00))),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 26, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))),
              ],
            ),
          ),
          if (!isOwned && widget.item.isRotating)
            Positioned(
              top: -7, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(99)),
                child: const Text('Novo', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPurple : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primaryPurple : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

// ── Small accessory card (4-col grid) ─────────────────────────────────────────

class _SmallAccessoryCard extends StatefulWidget {
  final ShopItem item;
  final bool isOwned;
  final String? setName;
  final WidgetRef ref;
  const _SmallAccessoryCard({required this.item, required this.isOwned, required this.ref, this.setName});

  @override
  State<_SmallAccessoryCard> createState() => _SmallAccessoryCardState();
}

class _SmallAccessoryCardState extends State<_SmallAccessoryCard> {
  bool _loading = false;

  String get _priceLabel {
    if (widget.item.priceGems != null) return '💎${widget.item.priceGems}';
    if (widget.item.priceCoins != null) return '🪙${widget.item.priceCoins}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isOwned = widget.isOwned;
    final isPremium = widget.item.isGemOnly;
    final borderColor = isOwned ? AppColors.success : isPremium ? AppColors.primaryPurple : AppColors.border;
    final bgColor = isOwned ? const Color(0xFF0E1A10) : isPremium ? AppColors.premiumBg : AppColors.surface;

    final profile = widget.ref.watch(userProfileProvider).valueOrNull;
    final canAfford = profile == null || _canAfford(profile, widget.item);

    return Opacity(
      opacity: isOwned ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 7, 5, 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.item.emoji ?? '🎁', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(widget.item.name,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (widget.setName != null) ...[
              const SizedBox(height: 1),
              Text(widget.setName!,
                  style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            if (isOwned)
              const Text('✓', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700))
            else if (!_loading)
              Opacity(
                opacity: canAfford ? 1.0 : 0.4,
                child: GestureDetector(
                  onTap: canAfford ? () async {
                    setState(() => _loading = true);
                    try {
                      final currency = widget.item.priceGems != null ? 'gems' : 'coins';
                      await _doPurchase(context, widget.ref, widget.item.itemRef, currency);
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPremium ? AppColors.primaryPurple : AppColors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_priceLabel,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                            color: isPremium ? Colors.white : const Color(0xFF1A0A00))),
                  ),
                ),
              )
            else
              const SizedBox(height: 20, child: Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)))),
          ],
        ),
      ),
    );
  }
}

// ── Ability set card ──────────────────────────────────────────────────────────

class _AbilitySetCard extends ConsumerStatefulWidget {
  final AbilitySet set;
  const _AbilitySetCard({required this.set});

  @override
  ConsumerState<_AbilitySetCard> createState() => _AbilitySetCardState();
}

class _AbilitySetCardState extends ConsumerState<_AbilitySetCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(ownedItemsProvider).valueOrNull ?? {};
    final ownedCount = widget.set.accessories.where((a) => owned.contains(a.itemRef)).length;
    final total = widget.set.accessories.length;
    final isComplete = total > 0 && ownedCount == total;
    final isPremium = widget.set.priceGems != null;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final canAffordGems = profile == null || (widget.set.priceGems != null && profile.gems >= widget.set.priceGems!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.premiumBg : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: isComplete ? AppColors.success : (isPremium ? AppColors.primaryPurple : AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.set.emoji ?? '🐱', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.set.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (widget.set.description != null)
                  Text(widget.set.description!, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                if (widget.set.abilityName != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.4)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('⚡ ${widget.set.abilityName!}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lightPurple)),
                      if (widget.set.abilityDescription != null)
                        Text(widget.set.abilityDescription!,
                            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.3)),
                    ]),
                  ),
                ],
              ])),
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF0E1A10), borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.success)),
                  child: const Text('✅ Desbloqueada', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.success)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: const Text('🔒 Habilidade', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Acessórios coletados', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('$ownedCount / $total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isComplete ? AppColors.success : AppColors.lightPurple)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0.0 : ownedCount / total,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(isComplete ? AppColors.success : AppColors.primaryPurple),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5, runSpacing: 5,
            children: widget.set.accessories.map((acc) {
              final accOwned = owned.contains(acc.itemRef);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accOwned ? const Color(0xFF0E1A10) : AppColors.background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: accOwned ? AppColors.success : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(acc.emoji ?? '🎀', style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text(acc.name, style: TextStyle(fontSize: 9, color: accOwned ? AppColors.success : AppColors.textSecondary)),
                  if (accOwned) ...[const SizedBox(width: 3), const Text('✓', style: TextStyle(fontSize: 9, color: AppColors.success))],
                ]),
              );
            }).toList(),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Como desbloquear a habilidade', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                const Row(children: [
                  Text('🎯', style: TextStyle(fontSize: 11)),
                  SizedBox(width: 5),
                  Expanded(child: Text('Complete o set coletando todos os acessórios', style: TextStyle(fontSize: 10, color: AppColors.textPrimary))),
                ]),
                if (isPremium) ...[
                  const SizedBox(height: 5),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Text('💎', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 5),
                    const Expanded(child: Text('Ou desbloqueie direto com Gemas', style: TextStyle(fontSize: 10, color: AppColors.textPrimary))),
                    _loading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Opacity(
                            opacity: canAffordGems ? 1.0 : 0.4,
                            child: GestureDetector(
                              onTap: canAffordGems ? () async {
                                setState(() => _loading = true);
                                try {
                                  await _doPurchase(context, ref, widget.set.itemRef, 'gems');
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(8)),
                                child: Text('💎 ${widget.set.priceGems}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ),
                  ]),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Coin pack card ────────────────────────────────────────────────────────────

class _CoinPackCard extends ConsumerStatefulWidget {
  final _CoinPack pack;
  const _CoinPackCard({required this.pack});

  @override
  ConsumerState<_CoinPackCard> createState() => _CoinPackCardState();
}

class _CoinPackCardState extends ConsumerState<_CoinPackCard> {
  bool _loading = false;

  Future<void> _confirmAndBuy(BuildContext context) async {
    final pack = widget.pack;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Text(pack.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(pack.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pack.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Valor', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(pack.price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmar', style: TextStyle(color: pack.isGem ? AppColors.lightPurple : AppColors.amber, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    setState(() => _loading = true);
    try {
      await _doPurchase(context, ref, pack.itemRef, 'brl');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final borderColor = pack.highlight ? (pack.isGem ? AppColors.primaryPurple : AppColors.amber) : AppColors.border;
    final bgColor = pack.highlight ? (pack.isGem ? AppColors.premiumBg : const Color(0xFF1A1408)) : AppColors.surface;
    final btnColor = pack.isGem ? AppColors.primaryPurple : AppColors.amber;
    final btnTextColor = pack.isGem ? Colors.white : const Color(0xFF1A0A00);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Text(pack.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pack.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(pack.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(pack.price, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pack.isGem ? AppColors.lightPurple : AppColors.amber)),
          ])),
          if (pack.highlight)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(99)),
              child: Text('Popular', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: btnTextColor)),
            ),
          GestureDetector(
            onTap: _loading ? null : () => _confirmAndBuy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(9)),
              child: _loading
                  ? SizedBox(width: 40, height: 16, child: Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: btnTextColor))))
                  : Text('Comprar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: btnTextColor)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Currency pill ─────────────────────────────────────────────────────────────

class _CurrencyPill extends StatelessWidget {
  final String emoji;
  final int value;
  final Color bg;
  final Color border;
  final Color color;
  const _CurrencyPill({required this.emoji, required this.value, required this.bg, required this.border, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
      child: Text('$emoji $value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
