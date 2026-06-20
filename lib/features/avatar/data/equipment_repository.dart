import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class EquipmentRepository {
  final Dio _dio;
  EquipmentRepository(this._dio);

  Future<Set<String>> fetchEquipped() async {
    final res = await _dio.get('/users/me/equipment');
    return (res.data as List).cast<String>().toSet();
  }

  Future<void> equip(String itemRef) async {
    await _dio.put('/users/me/equipment/$itemRef');
  }

  Future<void> unequip(String itemRef) async {
    await _dio.delete('/users/me/equipment/$itemRef');
  }
}

final equipmentRepositoryProvider = Provider<EquipmentRepository>(
  (ref) => EquipmentRepository(ref.watch(dioProvider)),
);

final equippedItemsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(equipmentRepositoryProvider).fetchEquipped(),
);
