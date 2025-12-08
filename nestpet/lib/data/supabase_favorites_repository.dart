/*
Propósito: Repositório para gerir favoritos de animais no Supabase.
- Fornece operações para listar, adicionar e remover favoritos por utilizador.

Observações:
- Usa a tabela `favorites` com colunas `user_id` e `animal_id`.
- Métodos simples e diretos; sem cache local aqui.
*/
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFavoritesRepository {
  // Cliente Supabase partilhado.
  final _client = Supabase.instance.client;

  // Inicialização (atualmente sem passos necessários).
  Future<void> init() async {}

  // Devolve lista de ids de animais favoritos do utilizador.
  Future<List<String>> getFavorites(String userId) async {
    final res = await _client.from('favorites').select('animal_id').eq('user_id', userId);
    final rows = res as List<dynamic>;
    return rows.map((r) => r['animal_id'].toString()).toList();
  }

  // Adiciona um favorito para o utilizador.
  Future<void> addFavorite(String userId, String animalId) async {
    await _client.from('favorites').insert({'user_id': userId, 'animal_id': animalId});
  }

  // Remove um favorito do utilizador.
  Future<void> removeFavorite(String userId, String animalId) async {
    await _client.from('favorites').delete().match({'user_id': userId, 'animal_id': animalId});
  }
}
