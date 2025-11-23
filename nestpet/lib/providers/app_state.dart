import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_animal_repository.dart';
import '../data/supabase_chat_repository.dart';
import '../data/supabase_favorites_repository.dart';
import '../models/animal.dart';

enum UserRole { user, org }

class AppState extends ChangeNotifier {
  UserRole? role;
  final animals = SupabaseAnimalRepository();
  final chat = SupabaseChatRepository();
  final favs = SupabaseFavoritesRepository();

  final Set<String> _favIds = {};

  Future<void> init() async {
    await animals.init();
    await favs.init();
    // carregar favoritos do Supabase para o user atual (se existir)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _favIds.clear();
    if (userId != null) {
      final list = await favs.getFavorites(userId);
      _favIds.addAll(list);
    }
  }

  void login(UserRole r) { role = r; notifyListeners(); }
  void logout() { role = null; notifyListeners(); }

  // Favoritos (só user)
  List<Animal> favorites() {
    final all = animals.all();
    return all.where((a) => _favIds.contains(a.id)).toList();
  }

  bool isFav(String id) => _favIds.contains(id);

  Future<void> toggleFav(String id) async {
    if (role == UserRole.org) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_favIds.contains(id)) {
      _favIds.remove(id);
      await favs.removeFavorite(userId, id);
    } else {
      _favIds.add(id);
      await favs.addFavorite(userId, id);
    }
    notifyListeners();
  }

  // CRUD
  Future<void> addAnimal(Animal a) async { await animals.add(a); notifyListeners(); }
  Future<void> updateAnimal(Animal a) async { await animals.updateAnimal(a); notifyListeners(); }
  Future<void> deleteAnimal(String id) async { await animals.delete(id); notifyListeners(); }
}
