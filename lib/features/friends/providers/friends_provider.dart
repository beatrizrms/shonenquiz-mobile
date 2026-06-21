import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/friends_models.dart';
import '../data/friends_repository.dart';

final myFriendCodeProvider = FutureProvider<String>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchMyCode(),
);

final friendsListProvider = FutureProvider<List<FriendSummary>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchFriends(),
);

final pendingRequestsProvider = FutureProvider<List<FriendRequest>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchPendingRequests(),
);

final friendProfileProvider = FutureProvider.family<FriendProfile, String>(
  (ref, userId) => ref.watch(friendsRepositoryProvider).fetchProfile(userId),
);

final friendRankingProvider = FutureProvider<List<RankingEntry>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchFriendRanking(),
);

// Estado local da busca por código
class FriendSearchNotifier extends StateNotifier<AsyncValue<FriendProfile?>> {
  final FriendsRepository _repo;
  FriendSearchNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> search(String code) async {
    if (code.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.searchByCode(code.trim()));
  }

  void clear() => state = const AsyncValue.data(null);
}

final friendSearchProvider = StateNotifierProvider.autoDispose<FriendSearchNotifier, AsyncValue<FriendProfile?>>(
  (ref) => FriendSearchNotifier(ref.watch(friendsRepositoryProvider)),
);
