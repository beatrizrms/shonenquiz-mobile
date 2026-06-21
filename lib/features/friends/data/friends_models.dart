export '../../ranking/data/ranking_repository.dart' show RankingEntry;

class FriendStats {
  final int totalSessions;
  final int accuracy;
  final int maxCombo;
  final int totalScore;

  const FriendStats({
    required this.totalSessions,
    required this.accuracy,
    required this.maxCombo,
    required this.totalScore,
  });

  factory FriendStats.fromJson(Map<String, dynamic> j) => FriendStats(
        totalSessions: (j['totalSessions'] as num).toInt(),
        accuracy: (j['accuracy'] as num).toInt(),
        maxCombo: (j['maxCombo'] as num).toInt(),
        totalScore: (j['totalScore'] as num).toInt(),
      );
}

class FriendSummary {
  final String friendshipId;
  final String userId;
  final String username;
  final int level;
  final String league;
  final String? avatarCatId;

  const FriendSummary({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.level,
    required this.league,
    this.avatarCatId,
  });

  factory FriendSummary.fromJson(Map<String, dynamic> j) => FriendSummary(
        friendshipId: j['friendshipId'] as String,
        userId: j['userId'] as String,
        username: j['username'] as String,
        level: (j['level'] as num).toInt(),
        league: j['league'] as String,
        avatarCatId: j['avatarCatId'] as String?,
      );

  String get leagueLabel {
    const l = {'bronze': '🥉 Bronze', 'silver': '🥈 Prata', 'gold': '🥇 Ouro',
                'diamond': '💎 Diamante', 'master': '⚔️ Mestre'};
    return l[league] ?? league;
  }
}

class FriendRequest {
  final String friendshipId;
  final String requesterId;
  final String requesterUsername;
  final int requesterLevel;
  final String requesterLeague;
  final String? requesterAvatarCatId;

  const FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    required this.requesterUsername,
    required this.requesterLevel,
    required this.requesterLeague,
    this.requesterAvatarCatId,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        friendshipId: j['friendshipId'] as String,
        requesterId: j['requesterId'] as String,
        requesterUsername: j['requesterUsername'] as String,
        requesterLevel: (j['requesterLevel'] as num).toInt(),
        requesterLeague: j['requesterLeague'] as String,
        requesterAvatarCatId: j['requesterAvatarCatId'] as String?,
      );
}

class FriendProfile {
  final String userId;
  final String username;
  final int level;
  final int xp;
  final String league;
  final int leaguePoints;
  final int lives;
  final String? avatarCatId;
  final String friendCode;
  final String? friendshipStatus;
  final FriendStats stats;

  const FriendProfile({
    required this.userId,
    required this.username,
    required this.level,
    required this.xp,
    required this.league,
    required this.leaguePoints,
    required this.lives,
    required this.avatarCatId,
    required this.friendCode,
    required this.friendshipStatus,
    required this.stats,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> j) => FriendProfile(
        userId: j['userId'] as String,
        username: j['username'] as String,
        level: (j['level'] as num).toInt(),
        xp: (j['xp'] as num).toInt(),
        league: j['league'] as String,
        leaguePoints: (j['leaguePoints'] as num).toInt(),
        lives: (j['lives'] as num).toInt(),
        avatarCatId: j['avatarCatId'] as String?,
        friendCode: j['friendCode'] as String,
        friendshipStatus: j['friendshipStatus'] as String?,
        stats: FriendStats.fromJson(j['stats'] as Map<String, dynamic>),
      );

  bool get isFriend => friendshipStatus == 'accepted';

  String get levelTitle {
    const t = {1: 'Espectador', 2: 'Iniciante', 3: 'Fã', 4: 'Otaku', 5: 'Senpai',
               6: 'Sensei', 7: 'Mestre', 8: 'Elite', 9: 'Rei dos Piratas', 10: 'Lendário'};
    return t[level] ?? 'Espectador';
  }

  String get leagueLabel {
    const l = {'bronze': '🥉 Bronze', 'silver': '🥈 Prata', 'gold': '🥇 Ouro',
                'diamond': '💎 Diamante', 'master': '⚔️ Mestre'};
    return l[league] ?? league;
  }
}

