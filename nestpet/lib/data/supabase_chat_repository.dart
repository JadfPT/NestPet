/*
Propósito: Repositório de chat usando Supabase para mensagens.
- Fornece leitura, envio de mensagens e marcação de lidas.
- Implementa subscrições por polling para novos conteúdos.

Observações:
- Estruturas de dados simples (Map) e modelo `Message` para a UI.
- Tabela usada: `messages`.
*/
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatRepository {
  // Cliente Supabase.
  final _client = Supabase.instance.client;

  // Busca mensagens por animal (e opcionalmente por utilizador), ordenadas por criação.
  Future<List<Map<String, dynamic>>> fetchMessages(String animalId, {String? userId}) async {
    final query = _client.from('messages').select().eq('animal_id', animalId);
    final res = userId == null ? await query.order('created_at') : await query.eq('user_id', userId).order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  // Envia/insere uma mensagem e tenta registar saída para debug.
  Future<void> sendMessage(String animalId, String userId, String fromRole, String content) async {
    try {
      final res = await _client.from('messages').insert({
        'animal_id': animalId,
        'user_id': userId,
        'from_role': fromRole,
        'content': content,
      }).select().maybeSingle();
      try {
        // ignore: avoid_print
        print('[chat] inserted message -> ${res ?? '<null>'}');
      } catch (_) {}
    } catch (e) {
      try {
        // ignore: avoid_print
        print('[chat] insert message failed: $e');
      } catch (_) {}
    }
  }

  // Marca todas as mensagens da conversa como lidas (se ainda não lidas).
  Future<void> markConversationRead(String animalId, String humanUserId) async {
    try {
        await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('animal_id', animalId)
          .eq('user_id', humanUserId)
          .filter('read_at', 'is', null);
    } catch (_) {}
  }

  // Envia mensagem construindo `fromRole` e `user_id` conforme origem.
  Future<void> send(String animalId, String senderId, String text, {String? humanUserId, String? fromRole}) async {

    final userIdToStore = humanUserId ?? senderId;
    final finalFromRole = fromRole ?? (userIdToStore == senderId ? 'user' : 'org');
    try {
      // ignore: avoid_print
      print('[chat] send called: animal=$animalId sender=$senderId storeUser=$userIdToStore fromRole=$finalFromRole');
    } catch (_) {}
    await sendMessage(animalId, userIdToStore, finalFromRole, text);
  }

  // Subscrição por polling a novas mensagens; evita duplicados com `seen`.
  Stream<Map<String, dynamic>> subscribeNewMessages(String animalId, {String? userId, DateTime? lastSeen}) {

    // Cria um controlador broadcast para permitir múltiplos ouvintes.
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Lista de ids já vistos para prevenir duplicados no stream.
    List<String> seen = [];
    Timer? timer;
    // Função para inicializar o ciclo de polling.
    Future<void> startPolling() async {
      // Função interna que executa uma consulta e emite novas mensagens.
      Future<void> poll() async {
        try {
          List<Map<String, dynamic>> rows;
          // Se existe um "último visto", limita às mensagens com `created_at` posterior.
          if (lastSeen != null) {
            final iso = lastSeen.toUtc().toIso8601String();
            final res = userId == null
                ? await _client.from('messages').select().eq('animal_id', animalId).gt('created_at', iso).order('created_at')
                : await _client.from('messages').select().eq('animal_id', animalId).eq('user_id', userId).gt('created_at', iso).order('created_at');
            rows = (res as List).cast<Map<String, dynamic>>();
          } else {
            // Caso contrário, obtém todas as mensagens ordenadas por criação, com ou sem filtro de utilizador.
            final res = userId == null
                ? await _client.from('messages').select().eq('animal_id', animalId).order('created_at')
                : await _client.from('messages').select().eq('animal_id', animalId).eq('user_id', userId).order('created_at');
            rows = (res as List).cast<Map<String, dynamic>>();
          }
          // Percorre resultados e emite apenas os não vistos.
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

      // Executa uma primeira consulta imediata e agenda polling de 2 em 2 segundos.
      await poll();
      timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());
    }

    // Inicia o processo de polling.
    startPolling();

    controller.onCancel = () {
      try {
        // Ao cancelar a subscrição, evita fugas de memória cancelando o timer.
        timer?.cancel();
      } catch (_) {}
    };

    // Expõe o stream para que a UI possa escutar novas mensagens.
    return controller.stream;
  }
}
