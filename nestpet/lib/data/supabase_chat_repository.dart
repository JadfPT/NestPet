import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class SupabaseChatRepository {
  final _client = Supabase.instance.client;
  // realtime channels map removed — using DB-backed typing_status + postgres_changes subscriptions

  Future<List<Map<String, dynamic>>> fetchMessages(String animalId, {String? userId}) async {
    final query = _client.from('messages').select().eq('animal_id', animalId);
    final res = userId == null ? await query.order('created_at') : await query.eq('user_id', userId).order('created_at');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendMessage(String animalId, String userId, String fromRole, String content) async {
    try {
      final res = await _client.from('messages').insert({
        'animal_id': animalId,
        'user_id': userId,
        'from_role': fromRole,
        'content': content,
      }).select().maybeSingle();
      // quick debug log to help diagnose mismatches during testing
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

  /// Upsert typing flag into `typing_status` table (requires migration).
  Future<void> sendTypingEventUpsert(String animalId, String humanUserId, bool isTyping) async {
    try {
      await _client.from('typing_status').upsert({
        'animal_id': animalId,
        'user_id': humanUserId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Subscribe to typing_status changes for this conversation using postgres_changes.
  Stream<Map<String, dynamic>> subscribeTypingEvents(String animalId, String humanUserId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    // Polling fallback for typing_status (simple and compatible):
    Timer? timer;
    Future<void> poll() async {
      try {
        final res = await _client.from('typing_status').select().eq('animal_id', animalId).eq('user_id', humanUserId).limit(1).maybeSingle();
        if (res != null) {
          controller.add(res);
        }
      } catch (_) {}
    }

    // initial poll and periodic checks
    poll();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => poll());

    controller.onCancel = () {
      try {
        timer?.cancel();
      } catch (_) {}
    };

    return controller.stream;
  }

  /// Mark all messages in this conversation as read (sets read_at)
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

  /// Send a lightweight typing event via a broadcast channel.
  Future<void> sendTypingEvent(String animalId, String humanUserId, bool isTyping) async {
    // Deprecated: use sendTypingEventUpsert(...) which writes into `typing_status`.
    return sendTypingEventUpsert(animalId, humanUserId, isTyping);
  }

  /// Subscribe to typing events for this conversation. Emits maps with keys: 'is_typing' and 'user_id'.
  Stream<Map<String, dynamic>> subscribeTyping(String animalId, String humanUserId) {
    // Deprecated: use subscribeTypingEvents(...) which listens to postgres_changes on typing_status.
    return Stream<Map<String, dynamic>>.empty();
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
  /// Compatibility helper used by existing screens.
  ///
  /// `senderId` should be the id of the currently authenticated user (the sender).
  /// For user -> senderId is the human user's id and `fromRole` will be 'user'.
  /// For org -> senderId is the org owner's id and `fromRole` will be 'org'.
  /// The repository needs to know the human participant's id to store in `user_id`.
  /// When called from a user screen, `senderId` is the human user and we set `userId = senderId`.
  /// When called from an org screen, the caller MUST pass the human participant id in `senderId` parameter
  /// (this is the existing convention in the app: org screens should call with the human user's id).
  Future<void> send(String animalId, String senderId, String text, {String? humanUserId, String? fromRole}) async {
    // `senderId` is the id of the authenticated sender (user or org owner).
    // `humanUserId` should be the human participant's id for this conversation. If omitted,
    // we assume the sender is the human and store `senderId` in `user_id`.
    final userIdToStore = humanUserId ?? senderId;
    // If caller didn't explicitly pass fromRole, infer: if senderId equals stored user id -> it's the human ('user'), else it's an org ('org').
    final finalFromRole = fromRole ?? (userIdToStore == senderId ? 'user' : 'org');
    try {
      // ignore: avoid_print
      print('[chat] send called: animal=$animalId sender=$senderId storeUser=$userIdToStore fromRole=$finalFromRole');
    } catch (_) {}
    await sendMessage(animalId, userIdToStore, finalFromRole, text);
  }

  /// Retorna um Stream que emite cada nova mensagem (map) para `animalId`.
  Stream<Map<String, dynamic>> subscribeNewMessages(String animalId, {String? userId, DateTime? lastSeen}) {
    // Try to use Supabase Realtime subscription (postgres_changes).
    // If realtime isn't available or subscription fails, fall back to polling.
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    // Helper: polling fallback (kept from previous implementation)
    List<String> seen = [];
    Timer? timer;
    Future<void> startPolling() async {
      Future<void> poll() async {
        try {
          // If lastSeen is provided, fetch only messages newer than lastSeen
          List<Map<String, dynamic>> rows;
          if (lastSeen != null) {
            final iso = lastSeen.toUtc().toIso8601String();
            final res = userId == null
                ? await _client.from('messages').select().eq('animal_id', animalId).gt('created_at', iso).order('created_at')
                : await _client.from('messages').select().eq('animal_id', animalId).eq('user_id', userId).gt('created_at', iso).order('created_at');
            rows = (res as List).cast<Map<String, dynamic>>();
          } else {
            final res = userId == null
                ? await _client.from('messages').select().eq('animal_id', animalId).order('created_at')
                : await _client.from('messages').select().eq('animal_id', animalId).eq('user_id', userId).order('created_at');
            rows = (res as List).cast<Map<String, dynamic>>();
          }
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
      await poll();
      timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());
    }

    // Use polling fallback as primary subscription mechanism (robust across SDK versions).
    startPolling();

    controller.onCancel = () {
      try {
        timer?.cancel();
      } catch (_) {}
    };

    return controller.stream;
  }
}
