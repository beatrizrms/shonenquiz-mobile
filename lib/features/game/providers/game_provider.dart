import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_models.dart';
import '../data/game_repository.dart';

enum GamePhase { idle, loading, bossEncounter, question, answerReveal, gameOver, victory }

class GameState {
  final GamePhase phase;
  final String? sessionId;
  final Question? currentQuestion;
  final AnswerResult? lastResult;
  final SessionSummary? summary;
  final int score;
  final int lives;
  final int combo;
  final int correctCount;
  final int questionsAnswered;
  final int questionsTotal;
  final int timerSeconds;    // duração total do timer por pergunta (vem da config do modo)
  final int secondsLeft;
  final String? selectedOptionId;
  final String? error;
  final bool isTimeOut;
  final int coinStage;
  final BossEncounter? pendingBoss;    // boss anunciado, aguardando tela de encontro
  final BossEncounter? activeBoss;     // boss cujo efeito está ativo na pergunta atual
  final String? activeBossEffect;      // "effectType:roundsRemaining" para efeitos persistentes

  // ── Ability state ─────────────────────────────────────────────────
  final Set<String> eliminatedOptionIds;   // opções eliminadas (sharingan / nen_gon)
  final String? revealedCorrectOptionId;   // opção correta revelada (eye_of_zeno)
  final String? shieldHelpType;            // B5: helpType que causou o shield (haki/izanagi/full_counter)
  final bool isTimerFrozen;                // za_warudo / reading_steiner
  final bool isHintRevealed;              // dr_stone — destaca o detalhe da pergunta
  final Map<int, int> slotCooldowns;       // slot index → perguntas restantes no cooldown
  final double pointMultiplier;            // multiply_points — próxima resposta correta vale N×

  bool get isShielded => shieldHelpType != null;

  const GameState({
    this.phase = GamePhase.idle,
    this.sessionId,
    this.currentQuestion,
    this.lastResult,
    this.summary,
    this.score = 0,
    this.lives = 3,
    this.combo = 0,
    this.correctCount = 0,
    this.questionsAnswered = 0,
    this.questionsTotal = 20,
    this.timerSeconds = 30,
    this.secondsLeft = 30,
    this.selectedOptionId,
    this.error,
    this.isTimeOut = false,
    this.coinStage = 0,
    this.pendingBoss,
    this.activeBoss,
    this.activeBossEffect,
    this.eliminatedOptionIds = const {},
    this.revealedCorrectOptionId,
    this.shieldHelpType,
    this.isTimerFrozen = false,
    this.isHintRevealed = false,
    this.slotCooldowns = const {},
    this.pointMultiplier = 1.0,
  });

  GameState copyWith({
    GamePhase? phase,
    String? sessionId,
    Question? currentQuestion,
    AnswerResult? lastResult,
    SessionSummary? summary,
    int? score,
    int? lives,
    int? combo,
    int? correctCount,
    int? questionsAnswered,
    int? questionsTotal,
    int? timerSeconds,
    int? secondsLeft,
    String? selectedOptionId,
    String? error,
    int? coinStage,
    BossEncounter? pendingBoss,
    BossEncounter? activeBoss,
    String? activeBossEffect,
    bool clearPendingBoss = false,
    bool clearActiveBoss = false,
    Set<String>? eliminatedOptionIds,
    String? revealedCorrectOptionId,
    String? shieldHelpType,
    bool? isTimerFrozen,
    bool? isHintRevealed,
    Map<int, int>? slotCooldowns,
    double? pointMultiplier,
    bool clearQuestion = false,
    bool clearResult = false,
    bool clearSelected = false,
    bool clearError = false,
    bool clearTimeOut = false,
    bool setTimeOut = false,
    bool clearAbilityState = false,
    bool clearShield = false,
  }) =>
      GameState(
        phase: phase ?? this.phase,
        sessionId: sessionId ?? this.sessionId,
        currentQuestion: clearQuestion ? null : (currentQuestion ?? this.currentQuestion),
        lastResult: clearResult ? null : (lastResult ?? this.lastResult),
        summary: summary ?? this.summary,
        score: score ?? this.score,
        lives: lives ?? this.lives,
        combo: combo ?? this.combo,
        correctCount: correctCount ?? this.correctCount,
        questionsAnswered: questionsAnswered ?? this.questionsAnswered,
        questionsTotal: questionsTotal ?? this.questionsTotal,
        timerSeconds: timerSeconds ?? this.timerSeconds,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        selectedOptionId: clearSelected ? null : (selectedOptionId ?? this.selectedOptionId),
        error: clearError ? null : (error ?? this.error),
        isTimeOut: clearTimeOut ? false : (setTimeOut ? true : this.isTimeOut),
        coinStage: coinStage ?? this.coinStage,
        pendingBoss: clearPendingBoss ? null : (pendingBoss ?? this.pendingBoss),
        activeBoss: clearActiveBoss ? null : (activeBoss ?? this.activeBoss),
        activeBossEffect: activeBossEffect ?? this.activeBossEffect,
        eliminatedOptionIds: clearAbilityState ? const {} : (eliminatedOptionIds ?? this.eliminatedOptionIds),
        revealedCorrectOptionId: clearAbilityState ? null : (revealedCorrectOptionId ?? this.revealedCorrectOptionId),
        shieldHelpType: (clearAbilityState || clearShield) ? null : (shieldHelpType ?? this.shieldHelpType),
        isTimerFrozen: clearAbilityState ? false : (isTimerFrozen ?? this.isTimerFrozen),
        isHintRevealed: clearAbilityState ? false : (isHintRevealed ?? this.isHintRevealed),
        // slotCooldowns não é resetado por clearAbilityState — decrementado per-pergunta
        slotCooldowns: slotCooldowns ?? this.slotCooldowns,
        // pointMultiplier persiste até ser consumido pelo próximo acerto (servidor reseta)
        pointMultiplier: clearAbilityState ? this.pointMultiplier : (pointMultiplier ?? this.pointMultiplier),
      );
}

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;
  DateTime? _questionStartedAt;

  /// true enquanto a QuizScreen está montada. Toda mutação de estado adiada
  /// (timer, Future.delayed, continuação async) precisa checar isto antes de
  /// escrever no state — caso contrário notifica um widget já defunct.
  bool _active = false;

  @override
  GameState build() => const GameState();

  GameRepository get _repo => ref.read(gameRepositoryProvider);

  Future<void> startSession({String mode = 'classic'}) async {
    _active = true;
    state = state.copyWith(phase: GamePhase.loading, clearError: true);
    try {
      final res = await _repo.startSession(mode: mode);
      if (!_active) return;
      state = GameState(
        phase: GamePhase.question,
        sessionId: res.sessionId,
        currentQuestion: res.firstQuestion,
        questionsTotal: res.questionsTotal,
        timerSeconds: res.timerSeconds,
        secondsLeft: res.timerSeconds,
        lives: res.lives,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(phase: GamePhase.idle, error: e.toString());
    }
  }

  Future<void> submitAnswer(String optionId) async {
    final session = state.sessionId;
    final question = state.currentQuestion;
    if (session == null || question == null) return;
    if (state.phase != GamePhase.question) return;

    _stopTimer();
    final timeTaken = _questionStartedAt != null
        ? DateTime.now().difference(_questionStartedAt!).inMilliseconds.clamp(200, 60000)
        : 1000;

    final helpUsed = state.shieldHelpType;  // B5: envia o helpType real do shield
    state = state.copyWith(
      phase: GamePhase.answerReveal,
      selectedOptionId: optionId,
      clearShield: true,
    );

    try {
      final result = await _repo.submitAnswer(
        sessionId: session,
        questionId: question.id,
        selectedOptionId: optionId,
        timeTakenMs: timeTaken,
        helpUsed: helpUsed,
      );

      // Usuário saiu do quiz enquanto aguardava o backend
      if (!_active) return;

      state = state.copyWith(
        lastResult: result,
        score: result.score,
        lives: result.livesRemaining,
        combo: result.currentCombo,
        correctCount: result.correctCount,    // B3/R4: vem do servidor
        questionsAnswered: result.questionsAnswered,
        coinStage: result.coinStage,
        pointMultiplier: result.isCorrect ? 1.0 : null,
      );

      if (result.isGameOver || result.isVictory) {
        final endSummary = SessionSummary(
          sessionId: session,
          status: result.sessionStatus,
          score: result.score,
          questionsTotal: result.questionsTotal,
          correctCount: result.correctCount,
          maxCombo: result.maxCombo,
          xpEarned: result.xpEarned,
          nekocoinsEarned: result.nekocoinsEarned,
        );
        state = state.copyWith(summary: endSummary);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!_active) return;
          state = state.copyWith(
            phase: result.isGameOver ? GamePhase.gameOver : GamePhase.victory,
          );
        });
      } else if (result.upcomingBoss != null) {
        // Registra o boss pendente — a transição para bossEncounter
        // acontece em advanceToNextQuestion, depois do result banner
        state = state.copyWith(
          pendingBoss: result.upcomingBoss,
          activeBossEffect: result.activeBossEffect,
        );
      } else {
        state = state.copyWith(activeBossEffect: result.activeBossEffect);
      }
    } catch (e) {
      if (!_active) return;
      state = state.copyWith(phase: GamePhase.question, error: e.toString(), secondsLeft: state.timerSeconds);
      _startTimer();
    }
  }

  /// Chamado quando o jogador confirma o boss encounter — avança para a pergunta boss
  void confirmBossAndContinue() {
    if (!_active) return;
    final boss = state.pendingBoss;
    final next = state.lastResult?.nextQuestion;
    if (next == null) return;

    // Decrementa cooldowns como faz advanceToNextQuestion
    final updatedCooldowns = Map<int, int>.fromEntries(
      state.slotCooldowns.entries
          .map((e) => MapEntry(e.key, e.value - 1))
          .where((e) => e.value > 0),
    );

    final cancelHelps     = boss?.effectType == 'cancel_active_help';
    final removeCoinStage = boss?.effectType == 'remove_coin_stage';
    final timePenalty     = boss?.effectType == 'time_penalty';

    // remove_coin_stage: aplica imediatamente no cliente para feedback visual imediato.
    // O servidor também aplica ao receber a resposta (source of truth).
    final newCoinStage = removeCoinStage
        ? (state.coinStage - 3).clamp(0, 15)
        : null;

    // time_penalty: desconta 10s do timer antes de iniciar
    final startSeconds = timePenalty
        ? (state.timerSeconds - 10).clamp(3, state.timerSeconds)
        : state.timerSeconds;

    state = state.copyWith(
      phase: GamePhase.question,
      currentQuestion: next,
      activeBoss: boss,
      clearPendingBoss: true,
      clearResult: true,
      clearSelected: true,
      // cancel_active_help cancela tudo; outros bosses preservam as ajudas ativas
      clearAbilityState: cancelHelps,
      pointMultiplier: cancelHelps ? 1.0 : null,
      coinStage: newCoinStage,
      secondsLeft: startSeconds,
      clearTimeOut: true,
      slotCooldowns: updatedCooldowns,
    );
    _startTimer();

    // force_random: highlight cíclico nas opções — o jogador ainda precisa escolher
  }

  void advanceToNextQuestion() {
    // Se há boss pendente, pausa o jogo e vai para a tela de encontro
    if (state.pendingBoss != null) {
      _stopTimer();
      state = state.copyWith(phase: GamePhase.bossEncounter);
      return;
    }

    final next = state.lastResult?.nextQuestion;
    if (next == null) return;
    // Decrementa todos os cooldowns ativos; remove os que chegaram a 0
    final updatedCooldowns = Map<int, int>.fromEntries(
      state.slotCooldowns.entries
          .map((e) => MapEntry(e.key, e.value - 1))
          .where((e) => e.value > 0),
    );
    state = state.copyWith(
      phase: GamePhase.question,
      currentQuestion: next,
      clearResult: true,
      clearSelected: true,
      secondsLeft: state.timerSeconds,
      clearTimeOut: true,
      clearAbilityState: true,
      clearActiveBoss: true,
      slotCooldowns: updatedCooldowns,
    );
    _startTimer();
  }

  Future<void> useHelp(int slotIndex, String helpType, {int cooldown = 3}) async {
    if (!_active) return;
    if (state.phase != GamePhase.question) return;
    if ((state.slotCooldowns[slotIndex] ?? 0) > 0) return;

    final question = state.currentQuestion;
    final session = state.sessionId;
    if (question == null || session == null) return;

    // Aplica cooldown imediatamente (UI responsiva)
    state = state.copyWith(slotCooldowns: {...state.slotCooldowns, slotIndex: cooldown});

    try {
      final result = await _repo.useHelp(
        sessionId: session,
        questionId: question.id,
        helpType: helpType,
      );
      if (!_active) return;

      switch (result.effect) {
        case 'eliminate_options':
          state = state.copyWith(eliminatedOptionIds: result.eliminatedOptionIds.toSet());
        case 'reveal_correct':
          if (result.correctOptionId != null) {
            state = state.copyWith(revealedCorrectOptionId: result.correctOptionId);
          }
        case 'add_seconds':
          state = state.copyWith(secondsLeft: (state.secondsLeft + result.secondsAdded).clamp(1, 120));
        case 'freeze_timer_seconds':
          _freezeTimerFor(result.freezeSeconds ?? 5);
        case 'freeze_timer':
          state = state.copyWith(isTimerFrozen: true);
        case 'extra_life':
          state = state.copyWith(lives: (state.lives + 1).clamp(0, 5));
        case 'shield':
          state = state.copyWith(shieldHelpType: helpType);
        case 'reveal_hint':
          state = state.copyWith(isHintRevealed: true);
        case 'swap_question':
        case 'skip_question':
          if (result.newQuestion != null) {
            state = state.copyWith(
              currentQuestion: result.newQuestion,
              clearAbilityState: true,
              slotCooldowns: {...state.slotCooldowns},  // mantém cooldowns existentes
              clearTimeOut: true,
              secondsLeft: state.timerSeconds,
            );
            _startTimer();
          }
        case 'multiply_points':
          state = state.copyWith(pointMultiplier: result.multiplier ?? 2.0);
        case 'revert_wrong':
          // Reverte o último erro: recupera 1 vida e avança o coinStage
          state = state.copyWith(
            lives: (state.lives + 1).clamp(0, 5),
            coinStage: (state.coinStage + 1).clamp(0, 15),
          );
        // no_op: slot fica usado, nada acontece
      }
    } catch (_) {
      // Desfaz o cooldown em caso de erro de rede
      if (!_active) return;
      final updated = Map<int, int>.from(state.slotCooldowns)..remove(slotIndex);
      state = state.copyWith(slotCooldowns: updated);
    }
  }

  void _freezeTimerFor(int seconds) async {
    if (!_active) return;
    state = state.copyWith(isTimerFrozen: true);
    await Future.delayed(Duration(seconds: seconds));
    if (!_active) return;
    state = state.copyWith(isTimerFrozen: false);
  }

  void timeOut() {
    if (!_active) return;
    final question = state.currentQuestion;
    final session = state.sessionId;
    if (question == null || session == null) return;
    if (state.phase != GamePhase.question) return;
    state = state.copyWith(setTimeOut: true);
    final firstOption = question.options.first.id;
    submitAnswer(firstOption);
  }

  /// Chamado pela QuizScreen ao ser desmontada. NÃO muta o state (os widgets
  /// já estão em teardown e notificá-los dispara o assert de defunct element):
  /// apenas marca como inativo e cancela o timer. O state é reiniciado de forma
  /// limpa na próxima chamada de [startSession].
  void detach() {
    _active = false;
    _stopTimer();
  }

  void _startTimer() {
    _stopTimer();
    _questionStartedAt = DateTime.now();
    // secondsLeft já foi definido pelo caller — não sobrescrever aqui
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_active) { _stopTimer(); return; }
      if (state.isTimerFrozen) return;

      // speed_timer: decrementa a cada 500ms em vez de 1000ms (velocidade dobrada)
      final isSpeedTimer = state.activeBoss?.effectType == 'speed_timer';

      // tick normal: decrementa apenas a cada 2 ticks (a cada segundo)
      if (!isSpeedTimer) {
        _halfSecondCount = (_halfSecondCount + 1) % 2;
        if (_halfSecondCount != 0) return;
      }

      if (state.secondsLeft <= 1) {
        _stopTimer();
        timeOut();
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - (isSpeedTimer ? 1 : 1));
      }
    });
  }

  int _halfSecondCount = 0;

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _halfSecondCount = 0;
  }

  void dispose() {
    detach();
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
