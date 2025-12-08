/*
Propósito: Fachada de repositório para animais, delegando em Supabase.
- Expõe operações de leitura/CRUD e utilitário para persistir ficheiros escolhidos.

Observações:
- Encapsula `SupabaseAnimalRepository` para separar lógica de dados da UI.
- `persistPickedFile` copia o ficheiro para a pasta de documentos da app com nome único.
*/
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/animal.dart';
import 'supabase_animal_repository.dart';

class AnimalRepository {
  // Implementação concreta baseada em Supabase.
  final SupabaseAnimalRepository _sup = SupabaseAnimalRepository();

  // Inicializa o repositório subjacente.
  Future<void> init() => _sup.init();

  // Lista com filtros opcionais (tipo, tamanho, idade máxima em meses).
  List<Animal> list({String? tipo, String? tamanho, int? idadeMaxMeses}) =>
      _sup.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMaxMeses);

  // Todos os animais (vista imutável do cache).
  List<Animal> all() => _sup.all();

  // Procura por id (assíncrono, consulta remota se necessário).
  Future<Animal?> byId(String id) => _sup.byId(id);

  // Procura por id na cache (sincrono).
  Animal? byIdSync(String id) => _sup.byIdSync(id);

  // Cria um novo animal.
  Future<Animal> add(Animal a) => _sup.add(a);

  // Atualiza dados de um animal existente.
  Future<void> updateAnimal(Animal a) => _sup.updateAnimal(a);

  // Remove um animal por id.
  Future<void> delete(String id) => _sup.delete(id);

  // Copia um ficheiro escolhido para armazenamento local da app, devolvendo o novo caminho.
  static Future<String> persistPickedFile(String originalPath, {String? forcedName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(originalPath);
    final name = forcedName ?? originalPath.split(Platform.pathSeparator).last;
    final dest = File('${dir.path}/media_${DateTime.now().microsecondsSinceEpoch}_$name');
    await dest.writeAsBytes(await file.readAsBytes());
    return dest.path;
  }
}
