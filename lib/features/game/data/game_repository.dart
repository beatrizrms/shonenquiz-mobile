import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'game_models.dart';

class GameRepository {
  final Dio _dio;
  GameRepository(this._dio);

  Future<StartSessionResponse> startSession({String mode = 'classic'}) async {
    final res = await _dio.post('/game/sessions', data: {'mode': mode});
    return StartSessionResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Question?> nextQuestion(String sessionId) async {
    final res = await _dio.get('/game/sessions/$sessionId/next');
    if (res.statusCode == 204) return null;
    return Question.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AnswerResult> submitAnswer({
    required String sessionId,
    required String questionId,
    required String selectedOptionId,
    required int timeTakenMs,
    String? helpUsed,
  }) async {
    final res = await _dio.post(
      '/game/sessions/$sessionId/answer',
      data: {
        'questionId': questionId,
        'selectedOptionId': selectedOptionId,
        'timeTakenMs': timeTakenMs,
        if (helpUsed != null) 'helpUsed': helpUsed,
      },
    );
    return AnswerResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<HelpResult> useHelp({
    required String sessionId,
    required String questionId,
    required String helpType,
  }) async {
    final res = await _dio.post(
      '/game/sessions/$sessionId/help',
      data: {'questionId': questionId, 'helpType': helpType},
    );
    return HelpResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SessionSummary> getSummary(String sessionId) async {
    final res = await _dio.get('/game/sessions/$sessionId/summary');
    return SessionSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GameModeConfig>> getGameModes() async {
    final res = await _dio.get('/game/modes');
    return (res.data as List)
        .map((e) => GameModeConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository(ref.watch(dioProvider)),
);
