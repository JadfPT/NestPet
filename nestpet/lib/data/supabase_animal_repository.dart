import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';

class SupabaseAnimalRepository {
  final _client = Supabase.instance.client;
  final List<Animal> _cache = [];

  Future<void> init() async {
    await refresh();
  }

  /// Refresh cache from Supabase and return list
  Future<List<Animal>> refresh() async {
    // Fetch user and prefer server-side metadata to decide which animals to load.
    String? userId;
    String? serverRole;
    try {
      final resp = await _client.auth.getUser();
      userId = resp.user?.id;
      final meta = resp.user?.userMetadata;
      if (meta != null && meta['role'] != null) serverRole = meta['role'] as String?;
    } catch (_) {
      // fallback to currentUser if getUser fails
      userId = _client.auth.currentUser?.id;
      try {
        final meta = _client.auth.currentUser?.userMetadata;
        if (meta != null && meta['role'] != null) serverRole = meta['role'] as String?;
      } catch (_) {}
    }

    late final dynamic res;
    if (serverRole == 'org' && userId != null) {
      // Organization: only load animals that belong to this org
      res = await _client.from('animals').select().eq('org_id', userId).order('created_at', ascending: false);
    } else {
      // Regular users: only load published animals
      res = await _client.from('animals').select().eq('is_published', true).order('created_at', ascending: false);
    }
    // ignore: unnecessary_cast
    final list = (res as List).map((r) => _mapToAnimal(r as Map<String, dynamic>)).toList();
    _cache
      ..clear()
      ..addAll(list);
    return _cache;
  }

  /// Synchronous view of cached animals
  List<Animal> all() => List.unmodifiable(_cache);

  /// Filtered synchronous list (same signature as previous local repository)
  List<Animal> list({String? tipo, String? tamanho, int? idadeMaxMeses}) {
    return _cache.where((a) {
      final okTipo = tipo == null || a.tipo == tipo;
      final okTam = tamanho == null || a.tamanho == tamanho;
      final okId = idadeMaxMeses == null || a.idadeMeses <= idadeMaxMeses;
      return okTipo && okTam && okId;
    }).toList();
  }

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

  /// Synchronous lookup in cache (may be null)
  Animal? byIdSync(String id) {
    try {
      return _cache.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Animal> add(Animal a) async {
    final userId = _client.auth.currentUser?.id;
    final data = {
      'id': a.id,
      'org_id': userId,
      'name': a.nome,
      'description': a.descricao,
      'image_path': jsonEncode(a.media.map((m) => m.path).toList()),
      'is_published': true,
    };
    await _client.from('animals').insert(data);
    _cache.insert(0, a);
    return a;
  }

  Future<void> updateAnimal(Animal a) async {
    final data = {
      'name': a.nome,
      'description': a.descricao,
      'image_path': jsonEncode(a.media.map((m) => m.path).toList()),
      'is_published': true,
    };
    await _client.from('animals').update(data).eq('id', a.id);
    final idx = _cache.indexWhere((x) => x.id == a.id);
    if (idx != -1) _cache[idx] = a;
  }

  Future<void> delete(String id) async {
    await _client.from('animals').delete().eq('id', id);
    _cache.removeWhere((a) => a.id == id);
  }

  Animal _mapToAnimal(Map<String, dynamic> r) {
    final mediaJson = r['image_path'];
    List<MediaItem> media = [];
    try {
      if (mediaJson != null) {
        final list = jsonDecode(mediaJson.toString()) as List<dynamic>;
        media = list.map((p) => MediaItem(path: p.toString(), type: p.toString().endsWith('.mp4') ? 'video' : 'image')).toList();
      }
    } catch (_) {}

    return Animal(
      id: r['id'].toString(),
      nome: r['name'] ?? '',
      tipo: r['type'] ?? 'Cão',
      sexo: r['sex'] ?? 'M',
      idadeMeses: 0,
      pesoKg: 0.0,
      tamanho: 'médio',
      descricao: r['description'] ?? '',
      media: media,
    );
  }
}
