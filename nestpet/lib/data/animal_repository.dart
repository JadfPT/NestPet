import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/animal.dart';
import 'supabase_animal_repository.dart';

/// Legacy shim kept to avoid touching many imports across the codebase.
/// Delegates to `SupabaseAnimalRepository` for persistence and keeps
/// `persistPickedFile` helper used by the UI for immediate previews.
class AnimalRepository {
  final SupabaseAnimalRepository _sup = SupabaseAnimalRepository();

  Future<void> init() => _sup.init();

  List<Animal> list({String? tipo, String? tamanho, int? idadeMaxMeses}) =>
      _sup.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMaxMeses);

  List<Animal> all() => _sup.all();

  Future<Animal?> byId(String id) => _sup.byId(id);

  Animal? byIdSync(String id) => _sup.byIdSync(id);

  Future<Animal> add(Animal a) => _sup.add(a);

  Future<void> updateAnimal(Animal a) => _sup.updateAnimal(a);

  Future<void> delete(String id) => _sup.delete(id);

  static Future<String> persistPickedFile(String originalPath, {String? forcedName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(originalPath);
    final name = forcedName ?? originalPath.split(Platform.pathSeparator).last;
    final dest = File('${dir.path}/media_${DateTime.now().microsecondsSinceEpoch}_$name');
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }
}
