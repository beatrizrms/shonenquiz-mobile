import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameSound {
  click,    // taps genéricos (botões, navegação)
  correct,  // resposta certa
  wrong,    // resposta errada
  combo,    // combo ativado / incrementado
  levelUp,  // subiu de nível
  gameOver, // perdeu todas as vidas
  victory,  // finalizou com vitória
  helpUsed, // usou uma ajuda
  timerLow, // timer entrando nos últimos segundos
  timesUp,  // dispara 1.5s após o timer zerar
  boss,     // boss apareceu
}

enum BackgroundMusic {
  classico,      // sounds/background_classico.wav
  sobrevivencia, // sounds/background_sobrevivencia.mp3
  menu,          // sounds/menu.wav
}

const _effectFiles = {
  GameSound.click:    'sounds/click.wav',
  GameSound.correct:  'sounds/correct.wav',
  GameSound.wrong:    'sounds/wrong.wav',
  GameSound.combo:    'sounds/combo.mp3',
  GameSound.levelUp:  'sounds/level_up.wav',
  GameSound.gameOver: 'sounds/game_over.wav',
  GameSound.victory:  'sounds/victory.mp3',
  GameSound.helpUsed: 'sounds/help_used.mp3',
  GameSound.timerLow: 'sounds/timer_low.wav',
  GameSound.timesUp:  'sounds/times_up.wav',
  GameSound.boss:     'sounds/boss.mp3',
};

const _musicFiles = {
  BackgroundMusic.classico:      'sounds/background_classico.wav',
  BackgroundMusic.sobrevivencia: 'sounds/background_sobrevivencia.mp3',
  BackgroundMusic.menu:          'sounds/menu.wav',
};

class SoundService {
  // Pool de efeitos sonoros (transitórios)
  final _pool = <GameSound, AudioPlayer>{};

  // Player dedicado para música de fundo — nunca misturado com efeitos
  AudioPlayer? _bgPlayer;
  BackgroundMusic? _currentBg;

  AudioPlayer get _bg {
    if (_bgPlayer != null) return _bgPlayer!;
    final player = AudioPlayer(playerId: 'background');
    // Contexto isolado: playback + mixWithOthers garante que o background
    // nunca seja interrompido por efeitos sonoros do próprio app.
    player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioMode: AndroidAudioMode.normal,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    ));
    _bgPlayer = player;
    return player;
  }

  bool _muted = false;
  bool get muted => _muted;

  void setMuted(bool value) => _muted = value;

  /// Pré-carrega todos os efeitos para eliminar latência no primeiro play.
  Future<void> preloadAll() async {
    for (final sound in GameSound.values) {
      final player = AudioPlayer();
      await player.setSource(AssetSource(_effectFiles[sound]!));
      _pool[sound] = player;
    }
  }

  // ── Efeitos sonoros ──────────────────────────────────────────────────────

  Future<void> play(GameSound sound) async {
    if (_muted) return;
    final player = _pool.putIfAbsent(sound, AudioPlayer.new);
    await player.stop();
    await player.setVolume(1.0);
    await player.play(AssetSource(_effectFiles[sound]!));
  }

  Future<void> playLoop(GameSound sound) async {
    if (_muted) return;
    final player = _pool.putIfAbsent(sound, AudioPlayer.new);
    await player.stop();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(1.0);
    await player.play(AssetSource(_effectFiles[sound]!));
  }

  Future<void> stop(GameSound sound) async {
    await _pool[sound]?.stop();
  }

  /// Para todos os efeitos. Não afeta a música de fundo.
  void stopAllEffects() {
    for (final player in _pool.values) {
      player.stop();
    }
  }

  // ── Música de fundo ──────────────────────────────────────────────────────

  Future<void> playBackground(BackgroundMusic music) async {
    if (_muted) return;
    _currentBg = music;
    final source = AssetSource(_musicFiles[music]!);
    await _bg.stop();
    await _bg.setReleaseMode(ReleaseMode.loop);
    await _bg.setVolume(0.7);
    await _bg.setSource(source);
    await _bg.resume();
  }

  Future<void> stopBackground() async {
    _currentBg = null;
    await _bgPlayer?.stop();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void dispose() {
    for (final p in _pool.values) {
      p.dispose();
    }
    _pool.clear();
    _bgPlayer?.dispose();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final svc = SoundService();
  ref.onDispose(svc.dispose);
  return svc;
});
