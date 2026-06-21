import 'dart:async';
import 'audio_manager.dart';
import 'sound_service.dart';
import '../../features/game/providers/game_provider.dart';

// Centraliza toda a lógica de áudio do QuizScreen.
// Widgets não conhecem SoundService nem AudioManager — apenas callbacks.
class GameSoundController {
  final AudioManager _audio;
  final SoundService _sound;

  Timer? _timesUpPlayTimer;
  Timer? _timesUpStopTimer;
  bool _timerLowActive = false;

  GameSoundController({required AudioManager this._audio, required SoundService this._sound});

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void activate(String mode) => _audio.onEnterGame(mode);

  void dispose() {
    _timesUpPlayTimer?.cancel();
    _timesUpStopTimer?.cancel();
    _sound.stopAllEffects();
    _audio.onLeaveGame();
  }

  // ── Reativo ao estado do jogo ──────────────────────────────────────────────

  void onGameStateChanged(GameState? prev, GameState next) {
    _handleTimerLow(prev, next);
    _handleAnswerReveal(prev, next);
    _handlePhaseTransition(prev, next);
  }

  void _handleTimerLow(GameState? prev, GameState next) {
    final questionChanged = next.phase == GamePhase.question &&
        prev?.phase == GamePhase.question &&
        prev?.currentQuestion?.id != next.currentQuestion?.id;
    final timeExtended = next.phase == GamePhase.question &&
        (prev?.secondsLeft ?? 0) < next.secondsLeft;

    if ((questionChanged || timeExtended) && _timerLowActive) {
      _sound.stop(GameSound.timerLow);
      _timerLowActive = false;
    }

    if (next.phase == GamePhase.question &&
        next.secondsLeft == 8 &&
        (prev?.secondsLeft ?? 9) > 8 &&
        !_timerLowActive) {
      _sound.playLoop(GameSound.timerLow);
      _timerLowActive = true;
    }
  }

  void _handleAnswerReveal(GameState? prev, GameState next) {
    if (prev?.phase != GamePhase.question || next.phase != GamePhase.answerReveal) return;

    if (_timerLowActive) {
      _sound.stop(GameSound.timerLow);
      _timerLowActive = false;
    }

    if (next.isTimeOut) {
      _timesUpPlayTimer = Timer(const Duration(milliseconds: 1500), () async {
        await _sound.play(GameSound.timesUp);
        _timesUpStopTimer = Timer(
          const Duration(milliseconds: 1500),
          () => _sound.stop(GameSound.timesUp),
        );
      });
    }
  }

  void _handlePhaseTransition(GameState? prev, GameState next) {
    if (prev?.phase == next.phase) return;

    if (next.phase == GamePhase.gameOver || next.phase == GamePhase.victory) {
      _timesUpPlayTimer?.cancel();
      _timesUpStopTimer?.cancel();
      _timerLowActive = false;
      _sound.stopAllEffects();
      _audio.onLeaveGame();
    }

    if (next.phase == GamePhase.gameOver) {
      _sound.play(GameSound.gameOver);
    } else if (next.phase == GamePhase.victory) {
      _sound.play(GameSound.victory);
    }
  }

  // ── Disparados pela UI ─────────────────────────────────────────────────────

  void onButtonTap() => _sound.play(GameSound.click);
  void onAnswerResult({required bool isCorrect}) =>
      _sound.play(isCorrect ? GameSound.correct : GameSound.wrong);
  void onCombo() => _sound.play(GameSound.combo);
}
