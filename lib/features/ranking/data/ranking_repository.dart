import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class RankingSeason {
  final String id;
  final String name;
  final DateTime endsAt;

  const RankingSeason({required this.id, required this.name, required this.endsAt});

  factory RankingSeason.fromJson(Map<String, dynamic> j) => RankingSeason(
        id: j['id'] as String,
        name: j['name'] as String,
        endsAt: DateTime.parse(j['endsAt'] as String),
      );

  Duration get remaining => endsAt.difference(DateTime.now().toUtc());
}

class RankingEntry {
  final int position;
  final String userId;
  final String username;
  final int level;
  final String league;
  final int score;
  final bool isCurrentUser;

  const RankingEntry({
    required this.position,
    required this.userId,
    required this.username,
    required this.level,
    required this.league,
    required this.score,
    required this.isCurrentUser,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j) => RankingEntry(
        position: (j['position'] as num).toInt(),
        userId: j['userId'] as String,
        username: j['username'] as String,
        level: (j['level'] as num).toInt(),
        league: j['league'] as String,
        score: (j['score'] as num).toInt(),
        isCurrentUser: j['isCurrentUser'] as bool? ?? false,
      );

  String get levelTitle {
    const t = {1: 'Espectador', 2: 'Iniciante', 3: 'Fã', 4: 'Otaku', 5: 'Senpai',
               6: 'Sensei', 7: 'Mestre', 8: 'Elite', 9: 'Rei dos Piratas', 10: 'Lendário'};
    return t[level] ?? 'Espectador';
  }
}

class RankingResult {
  final RankingSeason? season;
  final List<RankingEntry> entries;
  final RankingEntry? currentUserEntry;

  const RankingResult({required this.season, required this.entries, this.currentUserEntry});

  bool get isEmpty => entries.isEmpty;

  factory RankingResult.fromJson(Map<String, dynamic> j) => RankingResult(
        season: j['season'] != null ? RankingSeason.fromJson(j['season'] as Map<String, dynamic>) : null,
        entries: (j['entries'] as List).map((e) => RankingEntry.fromJson(e as Map<String, dynamic>)).toList(),
        currentUserEntry: j['currentUserEntry'] != null
            ? RankingEntry.fromJson(j['currentUserEntry'] as Map<String, dynamic>)
            : null,
      );
}

class RankingRepository {
  final Dio _dio;
  RankingRepository(this._dio);

  Future<RankingResult> fetchGlobal() async {
    final res = await _dio.get('/ranking/global');
    return RankingResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RankingResult> fetchLeague(String league) async {
    final res = await _dio.get('/ranking/league', queryParameters: {'league': league});
    return RankingResult.fromJson(res.data as Map<String, dynamic>);
  }
}

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(ref.watch(dioProvider)),
);

final globalRankingProvider = FutureProvider<RankingResult>(
  (ref) => ref.watch(rankingRepositoryProvider).fetchGlobal(),
);

final leagueRankingProvider = FutureProvider.family<RankingResult, String>(
  (ref, league) => ref.watch(rankingRepositoryProvider).fetchLeague(league),
);
