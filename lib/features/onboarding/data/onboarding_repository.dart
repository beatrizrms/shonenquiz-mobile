import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'anime_model.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(dioProvider));
});

class OnboardingRepository {
  final Dio _dio;
  OnboardingRepository(this._dio);

  Future<List<AnimeModel>> fetchAllAnimes() async {
    final res = await _dio.get('/animes');
    return (res.data as List).map((e) => AnimeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AnimeModel>> fetchUserAnimes() async {
    final res = await _dio.get('/users/me/animes');
    return (res.data as List).map((e) => AnimeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAnimePreferences(List<String> animeIds) async {
    await _dio.put('/users/me/animes', data: {'animeIds': animeIds});
  }

  Future<Map<String, dynamic>?> fetchAvatar() async {
    try {
      final res = await _dio.get('/users/me/avatar');
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAvatar({
    required String catName,
    required String breed,
    required String eyeColor,
    String? accessory,
    String? background,
  }) async {
    await _dio.put('/users/me/avatar', data: {
      'catName':    catName,
      'breed':      breed,
      'eyeColor':   eyeColor,
      'accessory':  accessory,
      'background': background,
    });
  }
}
