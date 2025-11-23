import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFavoritesRepository {
  final _client = Supabase.instance.client;

  Future<void> init() async {}

  Future<List<String>> getFavorites(String userId) async {
    final res = await _client.from('favorites').select('animal_id').eq('user_id', userId);
    final rows = res as List<dynamic>;
    return rows.map((r) => r['animal_id'].toString()).toList();
  }

  Future<void> addFavorite(String userId, String animalId) async {
    await _client.from('favorites').insert({'user_id': userId, 'animal_id': animalId});
  }

  Future<void> removeFavorite(String userId, String animalId) async {
    await _client.from('favorites').delete().match({'user_id': userId, 'animal_id': animalId});
  }
}
