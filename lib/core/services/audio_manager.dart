import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_service.dart';

// Ponto único de controle de áudio do app.
// Telas NÃO chamam SoundService diretamente — apenas métodos semânticos daqui.
// Para mudar o comportamento de áudio, edite apenas este arquivo.
class AudioManager {
  final SoundService _sound;
  AudioManager(this._sound);

  // ── Chamado quando o usuário entra em qualquer aba do menu principal
  //    (Ranking, Perfil, Loja). Home não tem música.
  Future<void> onEnterMenu() => _sound.playBackground(BackgroundMusic.menu);

  // ── Chamado quando o usuário volta para a aba Home do menu principal
  Future<void> onLeaveMenu() => _sound.stopBackground();

  // ── Chamado quando o QuizScreen é criado
  Future<void> onEnterGame(String mode) {
    final music = mode == 'survival'
        ? BackgroundMusic.sobrevivencia
        : BackgroundMusic.classico;
    return _sound.playBackground(music);
  }

  // ── Chamado quando o QuizScreen é descartado (dispose)
  Future<void> onLeaveGame() => _sound.stopBackground();

  // ── Efeitos sonoros (delegam ao SoundService)
  Future<void> play(GameSound sound) => _sound.play(sound);
  Future<void> playLoop(GameSound sound) => _sound.playLoop(sound);
  Future<void> stop(GameSound sound) => _sound.stop(sound);
  void stopAllEffects() => _sound.stopAllEffects();
}

final audioManagerProvider = Provider<AudioManager>((ref) {
  return AudioManager(ref.watch(soundServiceProvider));
});
