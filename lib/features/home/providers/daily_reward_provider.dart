import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class DailyLoginResult {
  final bool claimed;
  final int nekocoinsClaimed;
  const DailyLoginResult({required this.claimed, required this.nekocoinsClaimed});

  factory DailyLoginResult.fromJson(Map<String, dynamic> j) => DailyLoginResult(
        claimed: j['claimed'] as bool,
        nekocoinsClaimed: (j['nekocoinsClaimed'] as num).toInt(),
      );
}

// Chamado uma vez por sessão ao entrar na Home.
// Retorna null enquanto não foi chamado, DailyLoginResult depois.
final dailyLoginProvider = FutureProvider.autoDispose<DailyLoginResult>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.post('/users/me/daily-login');
  return DailyLoginResult.fromJson(response.data as Map<String, dynamic>);
});
