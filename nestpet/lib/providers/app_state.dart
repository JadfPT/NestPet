/*
Propósito: Estado global da aplicação (papel do utilizador, favoritos e dados).
- Centraliza papel (user/org), nome de exibição, favoritos e acesso a repositórios.
- Fornece métodos de login/logout e operações sobre animais e favoritos.

Observações:
- Integra com Supabase (auth, perfis) e repositórios específicos (animais, chat, favoritos).
- Usa `SessionService` para persistir o papel entre sessões quando necessário.
- Notifica ouvintes (`notifyListeners`) após mudanças para atualizar UI.
*/
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';
import '../data/supabase_animal_repository.dart';
import '../data/supabase_chat_repository.dart';
import '../data/supabase_favorites_repository.dart';
import '../models/animal.dart';

// Papel do utilizador
enum UserRole { user, org }

// Estado principal da aplicação.
class AppState extends ChangeNotifier {
  // Papel atual e nome de exibição.
  UserRole? role;
  String? displayName;
  // Repositórios de dados.
  final animals = SupabaseAnimalRepository();
  final chat = SupabaseChatRepository();
  final favs = SupabaseFavoritesRepository();

  // Cache local de favoritos (ids de animais).
  final Set<String> _favIds = {};

  // Indica se está em modo convidado (sem utilizador autenticado).
  bool get isGuest => Supabase.instance.client.auth.currentUser == null;

  // Inicializa repositórios, carrega favoritos e determina papel/displayName.
  Future<void> init() async {
    await animals.init();
    await favs.init();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _favIds.clear();
    if (userId != null) {
      final list = await favs.getFavorites(userId);
      _favIds.addAll(list);
    }

    final supaUser = Supabase.instance.client.auth.currentUser;
    if (supaUser != null) {
      try {
        displayName = supaUser.userMetadata?['displayName'] ?? supaUser.userMetadata?['name'];
      } catch (_) {
        displayName = null;
      }
      try {
        final meta = supaUser.userMetadata;
        final serverRole = meta != null && meta['role'] != null ? meta['role'] as String? : null;
        if (serverRole != null) {
          // Se metadados têm papel, usa-o diretamente.
          role = serverRole == 'org' ? UserRole.org : UserRole.user;
          notifyListeners();
          return;
        }
      } catch (_) {
        // ignorar
      }

      // Caso não exista nos metadados, tenta carregar da sessão.
      final saved = await SessionService.loadRole();
      if (saved != null) {
        role = saved == 'org' ? UserRole.org : UserRole.user;
        notifyListeners();
        return;
      }

      // Por omissão, assume utilizador.
      role = UserRole.user;
      notifyListeners();
    }
  }

  // Define papel e refresca dados após login; atualiza favoritos.
  void login(UserRole r) {
    role = r;
    try {
      displayName = Supabase.instance.client.auth.currentUser?.userMetadata?['displayName'] ?? Supabase.instance.client.auth.currentUser?.userMetadata?['name'];
    } catch (_) {
      displayName = null;
    }
    SessionService.saveRole(r == UserRole.org ? 'org' : 'user');

    animals.refresh().then((_) {
      notifyListeners();
    }).catchError((_) {
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      favs.getFavorites(userId).then((list) {
        _favIds.clear();
        _favIds.addAll(list);
        notifyListeners();
      }).catchError((_) {
        // ignorar
      });
    }

    notifyListeners();
  }

  // Termina sessão: tenta signOut, limpa caches/estado e notifica.
  void logout() {
    try {
      Supabase.instance.client.auth.signOut().catchError((_) {});
    } catch (_) {}
    role = null;
    
        // Limpa repositório de animais e favoritos.
        animals.clear();
      _favIds.clear();
    
    displayName = null;
    SessionService.clearRole();
    notifyListeners();
  }

  // Altera nome de exibição e notifica.
  void setDisplayName(String? name) {
    displayName = name;
    notifyListeners();
  }

  // Lista de animais favoritos.
  List<Animal> favorites() {
    final all = animals.all();
    return all.where((a) => _favIds.contains(a.id)).toList();
  }

  // Verifica se um id está nos favoritos.
  bool isFav(String id) => _favIds.contains(id);

  // Alterna favorito: atualiza localmente e sincroniza com repositório.
  Future<void> toggleFav(String id) async {
    if (role == UserRole.org || isGuest) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final removing = _favIds.contains(id);
    if (removing) {
      _favIds.remove(id);
    } else {
      _favIds.add(id);
    }
    notifyListeners();

    if (userId != null) {
      try {
        if (removing) {
          await favs.removeFavorite(userId, id);
        } else {
          await favs.addFavorite(userId, id);
        }
      } catch (_) {
        // ignorar
      }
    }
  }

  // Operações básicas sobre animais que notificam UI.
  Future<void> addAnimal(Animal a) async { await animals.add(a); notifyListeners(); }
  Future<void> updateAnimal(Animal a) async { await animals.updateAnimal(a); notifyListeners(); }
  Future<void> deleteAnimal(String id) async { await animals.delete(id); notifyListeners(); }
}
