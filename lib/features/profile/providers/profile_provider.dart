import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/user_profile.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/me');
  return UserProfile.fromJson(res.data as Map<String, dynamic>);
});

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/me/stats');
  return UserStats.fromJson(res.data as Map<String, dynamic>);
});

final recentSessionsProvider = FutureProvider<List<RecentSession>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/users/me/sessions/recent');
  return (res.data as List).map((e) => RecentSession.fromJson(e as Map<String, dynamic>)).toList();
});

final catNameProvider = FutureProvider<String>((ref) async {
  final data = await ref.watch(onboardingRepositoryProvider).fetchAvatar();
  return data?['catName'] as String? ?? '';
});
