class QuestionOption {
  final String id;
  final String optionText;
  final int sortOrder;

  const QuestionOption({required this.id, required this.optionText, required this.sortOrder});

  factory QuestionOption.fromJson(Map<String, dynamic> j) => QuestionOption(
        id: j['id'] as String,
        optionText: j['optionText'] as String,
        sortOrder: (j['sortOrder'] as num).toInt(),
      );
}

class Question {
  final String id;
  final String animeName;
  final String type;
  final String difficulty;
  final String questionText;
  final String? detailText;
  final String? mediaUrl;
  final List<QuestionOption> options;

  const Question({
    required this.id,
    required this.animeName,
    required this.type,
    required this.difficulty,
    required this.questionText,
    this.detailText,
    this.mediaUrl,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        animeName: j['animeName'] as String? ?? '',
        type: j['type'] as String,
        difficulty: j['difficulty'] as String,
        questionText: j['questionText'] as String,
        detailText: j['detailText'] as String?,
        mediaUrl: j['mediaUrl'] as String?,
        options: (j['options'] as List)
            .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
}

class StartSessionResponse {
  final String sessionId;
  final int questionsTotal;
  final int timerSeconds;
  final int lives;
  final Question firstQuestion;

  const StartSessionResponse({
    required this.sessionId,
    required this.questionsTotal,
    required this.timerSeconds,
    required this.lives,
    required this.firstQuestion,
  });

  factory StartSessionResponse.fromJson(Map<String, dynamic> j) => StartSessionResponse(
        sessionId: j['sessionId'] as String,
        questionsTotal: (j['questionsTotal'] as num).toInt(),
        timerSeconds: (j['timerSeconds'] as num? ?? 30).toInt(),
        lives: (j['lives'] as num? ?? 3).toInt(),
        firstQuestion: Question.fromJson(j['firstQuestion'] as Map<String, dynamic>),
      );
}

class GameModeConfig {
  final String mode;
  final String displayName;
  final String? description;
  final int questionsTotal;
  final int timerSeconds;
  final int lives;

  const GameModeConfig({
    required this.mode,
    required this.displayName,
    this.description,
    required this.questionsTotal,
    required this.timerSeconds,
    required this.lives,
  });

  factory GameModeConfig.fromJson(Map<String, dynamic> j) => GameModeConfig(
        mode: j['mode'] as String,
        displayName: j['displayName'] as String,
        description: j['description'] as String?,
        questionsTotal: (j['questionsTotal'] as num).toInt(),
        timerSeconds: (j['timerSeconds'] as num).toInt(),
        lives: (j['lives'] as num).toInt(),
      );
}

class BossEncounter {
  final String bossPowerId;
  final String villainName;
  final String powerName;
  final String raridade;
  final String effectType;
  final int effectDuration;
  final String description;

  const BossEncounter({
    required this.bossPowerId,
    required this.villainName,
    required this.powerName,
    required this.raridade,
    required this.effectType,
    required this.effectDuration,
    required this.description,
  });

  factory BossEncounter.fromJson(Map<String, dynamic> j) => BossEncounter(
        bossPowerId:     j['bossPowerId'] as String,
        villainName:     j['villainName'] as String,
        powerName:       j['powerName'] as String,
        raridade:        j['raridade'] as String,
        effectType:      j['effectType'] as String,
        effectDuration:  (j['effectDuration'] as num).toInt(),
        description:     j['description'] as String,
      );

  /// Cor de destaque por raridade
  static const raridadeColors = {
    'raro':     0xFF1D9E75,   // verde
    'epico':    0xFF7F77DD,   // roxo claro
    'lendario': 0xFFEF9F27,   // âmbar
  };

  int get raridadeColor => raridadeColors[raridade] ?? 0xFF534AB7;

  String get raridadeLabel => switch (raridade) {
    'raro'     => 'Raro',
    'epico'    => 'Épico',
    'lendario' => 'Lendário',
    _          => raridade,
  };
}

class AnswerResult {
  final bool isCorrect;
  final String correctOptionId;
  final int pointsEarned;
  final int currentCombo;
  final int maxCombo;
  final int correctCount;
  final int livesRemaining;
  final String sessionStatus;
  final int score;
  final int questionsAnswered;
  final int questionsTotal;
  final int xpEarned;
  final int nekocoinsEarned;
  final int coinStage;
  final Question? nextQuestion;
  final BossEncounter? upcomingBoss;
  final String? activeBossEffect;
  final bool dailyWinGemEarned;

  const AnswerResult({
    required this.isCorrect,
    required this.correctOptionId,
    required this.pointsEarned,
    required this.currentCombo,
    required this.maxCombo,
    required this.correctCount,
    required this.livesRemaining,
    required this.sessionStatus,
    required this.score,
    required this.questionsAnswered,
    required this.questionsTotal,
    required this.xpEarned,
    required this.nekocoinsEarned,
    required this.coinStage,
    this.nextQuestion,
    this.upcomingBoss,
    this.activeBossEffect,
    this.dailyWinGemEarned = false,
  });

  bool get isGameOver => sessionStatus == 'lost';
  bool get isVictory  => sessionStatus == 'won';
  bool get isActive   => sessionStatus == 'active';

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
        isCorrect: j['isCorrect'] as bool,
        correctOptionId: j['correctOptionId'] as String,
        pointsEarned: (j['pointsEarned'] as num).toInt(),
        currentCombo: (j['currentCombo'] as num).toInt(),
        maxCombo: (j['maxCombo'] as num).toInt(),
        correctCount: (j['correctCount'] as num).toInt(),
        livesRemaining: (j['livesRemaining'] as num).toInt(),
        sessionStatus: j['sessionStatus'] as String,
        score: (j['score'] as num).toInt(),
        questionsAnswered: (j['questionsAnswered'] as num).toInt(),
        questionsTotal: (j['questionsTotal'] as num).toInt(),
        xpEarned: (j['xpEarned'] as num).toInt(),
        nekocoinsEarned: (j['nekocoinsEarned'] as num).toInt(),
        coinStage: (j['coinStage'] as num).toInt(),
        nextQuestion: j['nextQuestion'] != null
            ? Question.fromJson(j['nextQuestion'] as Map<String, dynamic>)
            : null,
        upcomingBoss: j['upcomingBoss'] != null
            ? BossEncounter.fromJson(j['upcomingBoss'] as Map<String, dynamic>)
            : null,
        activeBossEffect: j['activeBossEffect'] as String?,
        dailyWinGemEarned: j['dailyWinGemEarned'] as bool? ?? false,
      );
}

class HelpResult {
  final String effect;
  final List<String> eliminatedOptionIds;
  final String? correctOptionId;
  final Question? newQuestion;
  final int secondsAdded;
  final int? freezeSeconds;
  final double? multiplier;

  const HelpResult({
    required this.effect,
    this.eliminatedOptionIds = const [],
    this.correctOptionId,
    this.newQuestion,
    this.secondsAdded = 0,
    this.freezeSeconds,
    this.multiplier,
  });

  factory HelpResult.fromJson(Map<String, dynamic> j) => HelpResult(
        effect: j['effect'] as String,
        eliminatedOptionIds: (j['eliminatedOptionIds'] as List? ?? []).cast<String>(),
        correctOptionId: j['correctOptionId'] as String?,
        newQuestion: j['newQuestion'] != null
            ? Question.fromJson(j['newQuestion'] as Map<String, dynamic>)
            : null,
        secondsAdded: (j['secondsAdded'] as num? ?? 0).toInt(),
        freezeSeconds: (j['freezeSeconds'] as num?)?.toInt(),
        multiplier: (j['multiplier'] as num?)?.toDouble(),
      );
}

class SessionAchievement {
  final String ruleId;
  final String label;
  final String bonusMetric;
  final String effectType;
  final double? bonusApplied;
  final int? questionNumber;

  const SessionAchievement({
    required this.ruleId,
    required this.label,
    required this.bonusMetric,
    required this.effectType,
    this.bonusApplied,
    this.questionNumber,
  });

  factory SessionAchievement.fromJson(Map<String, dynamic> j) => SessionAchievement(
        ruleId: j['ruleId'] as String,
        label: j['label'] as String,
        bonusMetric: j['bonusMetric'] as String,
        effectType: j['effectType'] as String,
        bonusApplied: (j['bonusApplied'] as num?)?.toDouble(),
        questionNumber: (j['questionNumber'] as num?)?.toInt(),
      );
}

class SessionSummary {
  final String sessionId;
  final String status;
  final int score;
  final int questionsTotal;
  final int correctCount;
  final int maxCombo;
  final int xpEarned;
  final int nekocoinsEarned;
  final List<SessionAchievement> achievements;

  const SessionSummary({
    required this.sessionId,
    required this.status,
    required this.score,
    required this.questionsTotal,
    required this.correctCount,
    required this.maxCombo,
    required this.xpEarned,
    required this.nekocoinsEarned,
    this.achievements = const [],
  });

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
        sessionId: j['sessionId'] as String,
        status: j['status'] as String,
        score: (j['score'] as num).toInt(),
        questionsTotal: (j['questionsTotal'] as num).toInt(),
        correctCount: (j['correctCount'] as num).toInt(),
        maxCombo: (j['maxCombo'] as num).toInt(),
        xpEarned: (j['xpEarned'] as num).toInt(),
        nekocoinsEarned: (j['nekocoinsEarned'] as num).toInt(),
        achievements: (j['achievements'] as List? ?? [])
            .map((e) => SessionAchievement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
