import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import 'friends_models.dart';

class FriendsRepository {
  final Dio _dio;
  FriendsRepository(this._dio);

  Future<String> fetchMyCode() async {
    final res = await _dio.get('/friends/my-code');
    return (res.data as Map<String, dynamic>)['friendCode'] as String;
  }

  Future<FriendProfile> searchByCode(String code) async {
    try {
      final res = await _dio.get('/friends/search', queryParameters: {'code': code.toUpperCase()});
      return FriendProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw ApiException('Código não encontrado');
      if (e.response?.statusCode == 400) throw ApiException('Não é possível adicionar a si mesmo');
      rethrow;
    }
  }

  Future<void> sendRequest(String friendCode) async {
    try {
      await _dio.post('/friends/request', data: {'friendCode': friendCode});
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      if (e.response?.statusCode == 409) throw ApiException(msg ?? 'Solicitação já existe');
      rethrow;
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    await _dio.post('/friends/$friendshipId/accept');
  }

  Future<void> removeFriend(String friendshipId) async {
    await _dio.post('/friends/$friendshipId/remove');
  }

  Future<List<FriendSummary>> fetchFriends() async {
    final res = await _dio.get('/friends');
    return (res.data as List).map((e) => FriendSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FriendRequest>> fetchPendingRequests() async {
    final res = await _dio.get('/friends/requests');
    return (res.data as List).map((e) => FriendRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FriendProfile> fetchProfile(String userId) async {
    final res = await _dio.get('/friends/$userId/profile');
    return FriendProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<RankingEntry>> fetchFriendRanking() async {
    final res = await _dio.get('/friends/ranking');
    return (res.data as List).map((e) => RankingEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(ref.watch(dioProvider)),
);
