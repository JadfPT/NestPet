import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/animal_repository.dart';
import '../data/chat_repository.dart';
import '../models/animal.dart';

enum UserRole { user, org }

class AppState extends ChangeNotifier {
  UserRole? role;
  final animals = AnimalRepository();
  final chat = ChatRepository();

  late Box favBox;
  final Set<String> _favIds = {};

  Future<void> init() async {
    await animals.init();

    const favName = 'favorites';
    // Box de favoritos com open seguro
    if (await Hive.boxExists(favName)) {
      try {
        favBox = await Hive.openBox(favName);
      } catch (_) {
        try { await Hive.deleteBoxFromDisk(favName); } catch (_) {}
        favBox = await Hive.openBox(favName);
      }
    } else {
      favBox = await Hive.openBox(favName);
    }

    _favIds
      ..clear()
      ..addAll(List<String>.from(favBox.get('ids', defaultValue: <String>[])));
  }

  void login(UserRole r) { role = r; notifyListeners(); }
  void logout() { role = null; notifyListeners(); }

  // Favoritos (só user)
  List<Animal> favorites() => animals.all().where((a) => _favIds.contains(a.id)).toList();
  bool isFav(String id) => _favIds.contains(id);
  void toggleFav(String id) {
    if (role == UserRole.org) return;
    _favIds.contains(id) ? _favIds.remove(id) : _favIds.add(id);
    favBox.put('ids', _favIds.toList());
    notifyListeners();
  }

  // CRUD
  Future<void> addAnimal(Animal a) async { await animals.add(a); notifyListeners(); }
  Future<void> updateAnimal(Animal a) async { await animals.updateAnimal(a); notifyListeners(); }
  Future<void> deleteAnimal(String id) async { await animals.delete(id); notifyListeners(); }
}
