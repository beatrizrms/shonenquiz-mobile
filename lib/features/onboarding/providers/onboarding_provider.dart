import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/anime_model.dart';
import '../data/onboarding_repository.dart';

// Verifica se o usuário já completou o onboarding
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final animes = await ref.watch(onboardingRepositoryProvider).fetchUserAnimes();
  return animes.isNotEmpty;
});

// Lista todos os animes disponíveis agrupados por categoria
final allAnimesProvider = FutureProvider<List<AnimeModel>>((ref) async {
  return ref.watch(onboardingRepositoryProvider).fetchAllAnimes();
});

// Animes selecionados pelo usuário durante o onboarding
final selectedAnimesProvider = StateProvider<Set<String>>((ref) => {});

// Avatar em construção
final avatarDraftProvider = StateProvider<AvatarDraft>((ref) => const AvatarDraft());

class AvatarDraft {
  final String catName;
  final String breed;
  final String eyeColor;
  final String? background;
  final String? accessory;

  const AvatarDraft({
    this.catName    = '',
    this.breed      = 'tabby-brown',
    this.eyeColor   = 'blue',
    this.background,
    this.accessory,
  });

  static const Object _unset = Object();

  AvatarDraft copyWith({
    String? catName,
    String? breed,
    String? eyeColor,
    Object? background = _unset,
    Object? accessory = _unset,
  }) => AvatarDraft(
    catName:    catName    ?? this.catName,
    breed:      breed      ?? this.breed,
    eyeColor:   eyeColor   ?? this.eyeColor,
    background: identical(background, _unset) ? this.background : background as String?,
    accessory:  identical(accessory, _unset) ? this.accessory : accessory as String?,
  );
}
