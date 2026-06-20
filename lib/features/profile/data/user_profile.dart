class UserProfile {
  final String id;
  final String username;
  final int level;
  final int xp;
  final int kokas;
  final int gems;
  final int lives;
  final String league;
  final int leaguePoints;

  const UserProfile({
    required this.id,
    required this.username,
    required this.level,
    required this.xp,
    required this.kokas,
    required this.gems,
    required this.lives,
    required this.league,
    required this.leaguePoints,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id:            j['id'] as String,
    username:      j['username'] as String,
    level:         (j['level'] as num).toInt(),
    xp:            (j['xp'] as num).toInt(),
    kokas:         (j['nekocoins'] as num? ?? 0).toInt(),
    gems:          (j['gems'] as num? ?? 0).toInt(),
    lives:         (j['lives'] as num? ?? 0).toInt(),
    league:        j['league'] as String? ?? 'bronze',
    leaguePoints:  (j['leaguePoints'] as num? ?? 0).toInt(),
  );

  String get levelTitle {
    const titles = {1: 'Espectador', 2: 'Iniciante', 3: 'Fã', 4: 'Otaku', 5: 'Senpai',
                    6: 'Sensei', 7: 'Mestre', 8: 'Elite', 9: 'Rei dos Piratas', 10: 'Lendário'};
    return titles[level] ?? 'Espectador';
  }

  String get leagueLabel {
    const labels = {
      'bronze': 'Liga Bronze', 'silver': 'Liga Prata', 'gold': 'Liga Ouro',
      'diamond': 'Liga Diamante', 'master': 'Mestre',
    };
    return labels[league] ?? 'Liga Bronze';
  }

  int get xpToNextLevel => level * 200;
}

class UserStats {
  final int totalSessions;
  final int accuracy;
  final int maxCombo;
  final int totalScore;

  const UserStats({
    required this.totalSessions,
    required this.accuracy,
    required this.maxCombo,
    required this.totalScore,
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    totalSessions: (j['totalSessions'] as num).toInt(),
    accuracy:      (j['accuracy'] as num).toInt(),
    maxCombo:      (j['maxCombo'] as num).toInt(),
    totalScore:    (j['totalScore'] as num).toInt(),
  );
}

class RecentSession {
  final String sessionId;
  final String mode;
  final String status;
  final int score;
  final int questionsAnswered;
  final int questionsTotal;

  const RecentSession({
    required this.sessionId,
    required this.mode,
    required this.status,
    required this.score,
    required this.questionsAnswered,
    required this.questionsTotal,
  });

  factory RecentSession.fromJson(Map<String, dynamic> j) => RecentSession(
    sessionId:         j['sessionId'] as String,
    mode:              j['mode'] as String,
    status:            j['status'] as String,
    score:             (j['score'] as num).toInt(),
    questionsAnswered: (j['questionsAnswered'] as num).toInt(),
    questionsTotal:    (j['questionsTotal'] as num).toInt(),
  );

  bool get isVictory => status == 'won';

  String get modeLabel => switch (mode) {
    'classic'    => 'Clássico',
    'timed'      => 'Contrarrelógio',
    'survival'   => 'Sobrevivência',
    'daily'      => 'Desafio diário',
    _            => mode,
  };
}
