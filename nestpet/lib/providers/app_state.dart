import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
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

    // If Supabase has a restored session, derive role from server metadata
    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null) {
      // prefer server-side metadata if present
      try {
        final meta = supaUser.userMetadata;
        final serverRole = meta != null && meta['role'] != null ? meta['role'] as String? : null;
        if (serverRole != null) {
          role = serverRole == 'org' ? UserRole.org : UserRole.user;
          notifyListeners();
          return;
        }
      } catch (_) {
        // ignore
      }

      // fallback to locally persisted role
      final saved = await SessionService.loadRole();
      if (saved != null) {
        role = saved == 'org' ? UserRole.org : UserRole.user;
        notifyListeners();
        return;
      }

      // default to user role if nothing else indicates org
      role = UserRole.user;
      notifyListeners();
    }
  }

  void login(UserRole r) {
    role = r;
    // persist role so it can be restored on app restart
    SessionService.saveRole(r == UserRole.org ? 'org' : 'user');
    notifyListeners();
  }

  void logout() {
    // Sign out from Supabase (fire-and-forget) and clear persisted role
    try {
      Supabase.instance.client.auth.signOut().catchError((_) {});
    } catch (_) {}
    role = null;
    SessionService.clearRole();
    notifyListeners();
  }

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
