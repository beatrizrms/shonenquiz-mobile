import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AbilitySlot {
  final int slotIndex;
  final String? setRef;
  final bool unlocked;

  const AbilitySlot({
    required this.slotIndex,
    required this.setRef,
    required this.unlocked,
  });

  factory AbilitySlot.fromJson(Map<String, dynamic> j) => AbilitySlot(
        slotIndex: j['slotIndex'] as int,
        setRef: j['setRef'] as String?,
        unlocked: j['unlocked'] as bool,
      );
}

class AbilitySlotRepository {
  final Dio _dio;
  AbilitySlotRepository(this._dio);

  Future<List<AbilitySlot>> fetchSlots() async {
    final res = await _dio.get('/users/me/ability-slots');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map(AbilitySlot.fromJson)
        .toList();
  }

  Future<void> equip(int slotIndex, String setRef) async {
    await _dio.put('/users/me/ability-slots/$slotIndex', data: {'setRef': setRef});
  }

  Future<void> unequip(int slotIndex) async {
    await _dio.delete('/users/me/ability-slots/$slotIndex');
  }
}

final abilitySlotRepositoryProvider = Provider<AbilitySlotRepository>(
  (ref) => AbilitySlotRepository(ref.watch(dioProvider)),
);

final abilitySlotsProvider = FutureProvider<List<AbilitySlot>>(
  (ref) => ref.watch(abilitySlotRepositoryProvider).fetchSlots(),
);
