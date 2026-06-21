import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/friends_models.dart';
import '../data/friends_repository.dart';
import '../providers/friends_provider.dart';
import 'add_friend_screen.dart';
import 'friend_profile_screen.dart';
import 'widgets/friend_card.dart';
import 'widgets/friend_request_card.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final pendingCount = requestsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('AMIGOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: .15)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFriendScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_outlined, size: 14, color: AppColors.lightPurple),
                          SizedBox(width: 5),
                          Text('Adicionar', style: TextStyle(fontSize: 12, color: AppColors.lightPurple, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                tabs: [
                  const Tab(text: 'Meus amigos'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Solicitações'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(99)),
                            child: Text('$pendingCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _FriendsList(onTap: (f) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FriendProfileScreen(userId: f.userId, friendshipId: f.friendshipId)),
                  )),
                  _RequestsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lista de amigos ──────────────────────────────────────────────────────────

class _FriendsList extends ConsumerWidget {
  final void Function(FriendSummary) onTap;
  const _FriendsList({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      error: (_, __) => _Retry(onRetry: () => ref.invalidate(friendsListProvider)),
      data: (friends) => friends.isEmpty
          ? const _EmptyState(icon: Icons.people_outline, message: 'Nenhum amigo ainda.\nAdicionem-se pelo código!')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(friendsListProvider),
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.surface,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FriendCard(friend: friends[i], onTap: () => onTap(friends[i])),
              ),
            ),
    );
  }
}

// ── Lista de solicitações ────────────────────────────────────────────────────

class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  Future<void> _accept(WidgetRef ref, String friendshipId) async {
    await ref.read(friendsRepositoryProvider).acceptRequest(friendshipId);
    ref.invalidate(pendingRequestsProvider);
    ref.invalidate(friendsListProvider);
  }

  Future<void> _decline(WidgetRef ref, String friendshipId) async {
    await ref.read(friendsRepositoryProvider).removeFriend(friendshipId);
    ref.invalidate(pendingRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      error: (_, __) => _Retry(onRetry: () => ref.invalidate(pendingRequestsProvider)),
      data: (requests) => requests.isEmpty
          ? const _EmptyState(icon: Icons.mark_email_unread_outlined, message: 'Nenhuma solicitação pendente')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(pendingRequestsProvider),
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.surface,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => FriendRequestCard(
                  request: requests[i],
                  onAccept: () => _accept(ref, requests[i].friendshipId),
                  onDecline: () => _decline(ref, requests[i].friendshipId),
                ),
              ),
            ),
    );
  }
}

// ── Auxiliares ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Falha ao carregar', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
