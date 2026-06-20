import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/game_models.dart';
import '../data/game_repository.dart';

final gameModeConfigsProvider = FutureProvider<List<GameModeConfig>>((ref) {
  ref.keepAlive();  // configs de modo raramente mudam — evita refetch a cada rebuild
  return ref.read(gameRepositoryProvider).getGameModes();
});

/// Retorna a config de um modo específico, ou null se ainda carregando/erro
extension GameModeConfigsX on List<GameModeConfig> {
  GameModeConfig? forMode(String mode) =>
      cast<GameModeConfig?>().firstWhere((c) => c?.mode == mode, orElse: () => null);
}
