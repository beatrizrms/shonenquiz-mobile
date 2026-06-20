import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'ability_set.dart';
import 'shop_item.dart';

class ShopRepository {
  final Dio _dio;
  const ShopRepository(this._dio);

  Future<List<ShopItem>> fetchItems({String? category}) async {
    final res = await _dio.get('/shop/items', queryParameters: category != null ? {'category': category} : null);
    return (res.data as List).map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopItem>> fetchFeatured() async {
    final res = await _dio.get('/shop/featured');
    return (res.data as List).map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchOwned() async {
    final res = await _dio.get('/shop/owned');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<AbilitySet>> fetchAbilitySets() async {
    final res = await _dio.get('/shop/items/ability-sets');
    return (res.data as List).map((e) => AbilitySet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> purchase(String itemRef, String currency) async {
    try {
      final res = await _dio.post('/shop/purchase', data: {'itemRef': itemRef, 'currency': currency});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepository(ref.watch(dioProvider)),
);

final ownedItemsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  final items = await repo.fetchOwned();
  return items.map((e) => e['itemRef'] as String).toSet();
});

final abilitySetsProvider = FutureProvider<List<AbilitySet>>((ref) async {
  return ref.watch(shopRepositoryProvider).fetchAbilitySets();
});

final accessoriesProvider = FutureProvider<List<ShopItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).fetchItems(category: 'accessory');
});

final featuredItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).fetchFeatured();
});
