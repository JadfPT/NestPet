import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class SupabaseChatRepository {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMessages(String animalId) async {
    final res = await _client.from('messages').select().eq('animal_id', animalId).order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendMessage(String animalId, String userId, String fromRole, String content) async {
    await _client.from('messages').insert({
      'animal_id': animalId,
      'user_id': userId,
      'from_role': fromRole,
      'content': content,
    });
  }

  // --- Compat layer para a API antiga usada no app

  /// Compat: retorna lista de Message (sincronamente obtida com fetchMessages)
  /// Compat: retorna lista de Message (sincronamente obtida com fetchMessages)
  /// Atualmente devolve uma lista vazia para compatibilidade; recomenda-se atualizar as screens
  /// para usar `fetchMessages` ou `subscribeNewMessages` para dados em tempo real.
  List<Message> forAnimal(String animalId) {
    return [];
  }

  /// Compat: envia mensagem usando a API similar à antiga `send(animalId, from, text)`
  Future<void> send(String animalId, String from, String text) async {
    await sendMessage(animalId, from, from, text);
  }

  /// Retorna um Stream que emite cada nova mensagem (map) para `animalId`.
  Stream<Map<String, dynamic>> subscribeNewMessages(String animalId) {
    // Fallback polling-based stream (compatible across supabase/realtime client versions).
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    List<String> seen = [];
    Timer? timer;

    Future<void> poll() async {
      try {
        final rows = await fetchMessages(animalId);
        for (final r in rows) {
          final id = (r['id'] ?? '').toString();
          if (id.isEmpty) continue;
          if (!seen.contains(id)) {
            seen.add(id);
            controller.add(r);
          }
        }
      } catch (_) {}
    }

    // initial poll
    poll();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }
}
