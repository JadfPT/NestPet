/*
Propósito: Repositório de animais usando Supabase com cache local.
- Carrega, lista, adiciona, atualiza e remove animais.
- Adapta consultas conforme o papel (org vê os seus; user vê publicados).

Observações:
- Mantém um cache `_cache` para reduzir acessos e atualizar UI rapidamente.
- Converte campos entre diferentes nomes/tipos ao mapear resultados (`_mapToAnimal`).
- `image_path` guarda lista (JSON) de caminhos/URLs das media.
*/
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';

class SupabaseAnimalRepository {
  // Cliente Supabase e cache local.
  final _client = Supabase.instance.client;
  final List<Animal> _cache = [];

  // Inicializa carregando dados.
  Future<void> init() async {
    await refresh();
  }

  // Recarrega lista de animais conforme papel do utilizador.
  Future<List<Animal>> refresh() async {
    String? userId;
    String? serverRole;
    try {
      // Tenta obter utilizador via SDK (getUser) e extrair metadados.
      final resp = await _client.auth.getUser();
      userId = resp.user?.id;
      final meta = resp.user?.userMetadata;
      if (meta != null && meta['role'] != null) serverRole = meta['role'] as String?;
    } catch (_) {
      // Fallback para `currentUser` se getUser falhar.
      userId = _client.auth.currentUser?.id;
      try {
        final meta = _client.auth.currentUser?.userMetadata;
        if (meta != null && meta['role'] != null) serverRole = meta['role'] as String?;
      } catch (_) {}
    }

    late final dynamic res;
    // Se é organização, lista apenas animais dessa org; caso contrário, só publicados.
    if (serverRole == 'org' && userId != null) {
      res = await _client.from('animals').select().eq('org_id', userId).order('created_at', ascending: false);
    } else {
      res = await _client.from('animals').select().eq('is_published', true).order('created_at', ascending: false);
    }
    // ignore: unnecessary_cast
    final list = (res as List).map((r) => _mapToAnimal(r as Map<String, dynamic>)).toList();
    // Atualiza cache com os resultados mais recentes.
    _cache
      ..clear()
      ..addAll(list);
    return _cache;
  }

  // Devolve cópia imutável do cache.
  List<Animal> all() => List.unmodifiable(_cache);

  // Limpa o cache local.
  void clear() {
    _cache.clear();
  }

  // Filtra animais por tipo/tamanho/idade máxima.
  List<Animal> list({String? tipo, String? tamanho, int? idadeMaxMeses}) {
    return _cache.where((a) {
      final okTipo = tipo == null || a.tipo == tipo;
      final okTam = tamanho == null || a.tamanho == tamanho;
      final okId = idadeMaxMeses == null || a.idadeMeses <= idadeMaxMeses;
      return okTipo && okTam && okId;
    }).toList();
  }

  // Obtém por id; consulta remota se não estiver em cache e atualiza cache.
  Future<Animal?> byId(String id) async {
    final cached = byIdSync(id);
    if (cached != null) return cached;
    final res = await _client.from('animals').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    // ignore: unnecessary_cast
    final a = _mapToAnimal(res as Map<String, dynamic>);
    _cache.add(a);
    return a;
  }

  // Procura sincronamente no cache.
  Animal? byIdSync(String id) {
    try {
      return _cache.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // Adiciona um animal: constrói mapa de dados, insere e pré-insere no cache no topo.
  Future<Animal> add(Animal a) async {
    final userId = _client.auth.currentUser?.id;
    // Normaliza o tipo para evitar caracteres especiais na BD.
    final dbType = a.tipo.replaceAll('ã', 'a').replaceAll('Ã', 'A');
    final data = {
      'id': a.id,
      'org_id': userId,
      'name': a.nome,
      'type': dbType,
      'sex': a.sexo,
      'age_months': a.idadeMeses,
      'weight_kg': a.pesoKg,
      'tamanho': a.tamanho,
      'personality': a.personalidade,
      'life_expectancy_years': a.expectativaVidaAnos,
      'vaccinated': a.vacinado,
      'characteristics': a.caracteristicas,
      'color': a.cor,
      'description': a.descricao,
      // Guarda apenas caminhos das media como JSON.
      'image_path': jsonEncode(a.media.map((m) => m.path).toList()),
      'is_published': true,
    };
    // ignore: avoid_print
    print('SupabaseAnimalRepository.add: inserting data: $data');
    final inserted = await _client.from('animals').insert(data).select().maybeSingle();
    // ignore: avoid_print
    print('SupabaseAnimalRepository.add: insert result: $inserted');
    // Atualiza cache local (inserção no topo para refletir ordem recente).
    _cache.insert(0, a);
    return a;
  }

  // Atualiza um animal existente e sincroniza cache.
  Future<void> updateAnimal(Animal a) async {
    final dbType = a.tipo.replaceAll('ã', 'a').replaceAll('Ã', 'A');
    final data = {
      'name': a.nome,
      'type': dbType,
      'sex': a.sexo,
      'age_months': a.idadeMeses,
      'weight_kg': a.pesoKg,
      'tamanho': a.tamanho,
      'personality': a.personalidade,
      'life_expectancy_years': a.expectativaVidaAnos,
      'vaccinated': a.vacinado,
      'characteristics': a.caracteristicas,
      'color': a.cor,
      'description': a.descricao,
      'image_path': jsonEncode(a.media.map((m) => m.path).toList()),
      'is_published': true,
    };
    // ignore: avoid_print
    print('SupabaseAnimalRepository.updateAnimal: updating id=${a.id} data=${data.toString()}');
    final updated = await _client.from('animals').update(data).eq('id', a.id).select().maybeSingle();
    // ignore: avoid_print
    print('SupabaseAnimalRepository.updateAnimal: update result: $updated');
    // Substitui no cache o objeto atualizado.
    final idx = _cache.indexWhere((x) => x.id == a.id);
    if (idx != -1) _cache[idx] = a;
  }

  // Remove um animal na BD e do cache.
  Future<void> delete(String id) async {
    await _client.from('animals').delete().eq('id', id);
    _cache.removeWhere((a) => a.id == id);
  }

  // Converte um registo da BD para `Animal`, incluindo media vinda de JSON.
  Animal _mapToAnimal(Map<String, dynamic> r) {
    final mediaJson = r['image_path'];
    List<MediaItem> media = [];
    try {
      if (mediaJson != null) {
        // `image_path` é uma lista JSON de caminhos/URLs.
        final list = jsonDecode(mediaJson.toString()) as List<dynamic>;
        media = list.map((p) => MediaItem(path: p.toString(), type: p.toString().endsWith('.mp4') ? 'video' : 'image')).toList();
      }
    } catch (_) {}

    // Normaliza tipo para valores esperados na app.
    var tipoFromDb = (r['type'] ?? r['tipo'] ?? 'Cao').toString();
    if (tipoFromDb.toLowerCase() == 'cao') tipoFromDb = 'Cão';
    if (tipoFromDb.toLowerCase() == 'outro') tipoFromDb = 'Outro';

    return Animal(
      id: r['id'].toString(),
      nome: r['name'] ?? '',
      tipo: tipoFromDb,
      sexo: r['sex'] ?? r['sexo'] ?? 'M',
      // Parsing robusto para inteiros/doubles com fallbacks.
      idadeMeses: (r['age_months'] ?? r['idadeMeses'] ?? 0) is int
          ? (r['age_months'] ?? r['idadeMeses'] ?? 0) as int
          : int.tryParse((r['age_months'] ?? r['idadeMeses'] ?? '0').toString()) ?? 0,
      pesoKg: (r['weight_kg'] ?? r['pesoKg'] ?? 0.0) is double
          ? (r['weight_kg'] ?? r['pesoKg'] ?? 0.0) as double
          : double.tryParse((r['weight_kg'] ?? r['pesoKg'] ?? '0').toString()) ?? 0.0,
      tamanho: r['tamanho'] ?? r['size'] ?? 'médio',
      descricao: r['description'] ?? r['descricao'] ?? '',
      personalidade: r['personality'] ?? r['personalidade'] ?? '',
      expectativaVidaAnos: (r['life_expectancy_years'] ?? r['expectativaVidaAnos'] ?? 0) is int
        ? (r['life_expectancy_years'] ?? r['expectativaVidaAnos'] ?? 0) as int
        : int.tryParse((r['life_expectancy_years'] ?? r['expectativaVidaAnos'] ?? '0').toString()) ?? 0,
      vacinado: (r['vaccinated'] ?? r['vacinado'] ?? false) is bool
        ? (r['vaccinated'] ?? r['vacinado'] ?? false) as bool
        : (r['vaccinated'] ?? r['vacinado'] ?? 'false').toString().toLowerCase() == 'true',
      caracteristicas: r['characteristics'] ?? r['caracteristicas'] ?? '',
      cor: r['color'] ?? r['cor'] ?? '',
      media: media,
    );
  }
}
