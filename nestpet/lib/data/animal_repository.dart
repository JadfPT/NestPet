import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/animal.dart';

class AnimalRepository {
  static const _boxName = 'animals';
  late Box<Animal> _box;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(MediaItemAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AnimalAdapter());

    // 1) Se existir uma box antiga, tenta abrir; se falhar, limpa com segurança.
    if (await Hive.boxExists(_boxName)) {
      try {
        _box = await Hive.openBox<Animal>(_boxName);
      } catch (_) {
        await _safeDeleteBoxFromDisk(_boxName);
        _box = await Hive.openBox<Animal>(_boxName);
      }
    } else {
      // 2) Não existe -> abre nova
      _box = await Hive.openBox<Animal>(_boxName);
    }
  }

  List<Animal> list({String? tipo, String? tamanho, int? idadeMaxMeses}) {
    final items = _box.values.toList();
    return items.where((a) {
      final okTipo = tipo == null || a.tipo == tipo;
      final okTam  = tamanho == null || a.tamanho == tamanho;
      final okId   = idadeMaxMeses == null || a.idadeMeses <= idadeMaxMeses;
      return okTipo && okTam && okId;
    }).toList();
  }

  List<Animal> all() => _box.values.toList();
  Animal? byId(String id) => _box.get(id);

  Future<Animal> add(Animal a) async { await _box.put(a.id, a); return a; }
  Future<void> updateAnimal(Animal a) async => _box.put(a.id, a);
  Future<void> delete(String id) async => _box.delete(id);

  static Future<String> persistPickedFile(String originalPath, {String? forcedName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(originalPath);
    final name = forcedName ?? originalPath.split(Platform.pathSeparator).last;
    final dest = File('${dir.path}/media_${DateTime.now().microsecondsSinceEpoch}_$name');
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }
}

/// Apaga a box do disco, ignorando erros de ficheiros em falta (.lock, .hive, etc.)
Future<void> _safeDeleteBoxFromDisk(String name) async {
  try {
    await Hive.deleteBoxFromDisk(name);
  } catch (_) {
    // Falhou o deleteBoxFromDisk? Faz limpeza manual, mas sem lançar.
    final dir = await getApplicationDocumentsDirectory();
    final base = '${dir.path}/$name';
    for (final ext in ['.hive', '.lock', '.hiveS', '.hiveC']) {
      try { final f = File('$base$ext'); if (await f.exists()) await f.delete(); } catch (_) {}
    }
  }
}
