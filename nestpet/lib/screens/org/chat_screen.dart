import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/message.dart';

class OrgChatScreen extends StatefulWidget {
  final String animalId; // conversa referente a um animal
  const OrgChatScreen({super.key, required this.animalId});

  @override
  State<OrgChatScreen> createState() => _OrgChatScreenState();
}

class _OrgChatScreenState extends State<OrgChatScreen> {
  final ctrl = TextEditingController();
  final List<Message> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  Widget build(BuildContext context) {
    final animal = context.watch<AppState>().animals.byIdSync(widget.animalId);
    final msgs = _messages;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat • ${animal?.nome ?? "Animal"}'),
        actions: [
          IconButton(
            onPressed: () => context.go('/org'),
            icon: const Icon(Icons.list_alt),
            tooltip: 'Os seus animais',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                final isOrg = m.from == 'org';
                return Align(
                  alignment: isOrg ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOrg
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(hintText: 'Responder...'),
                    onSubmitted: (_) => _send(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(context),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _send(BuildContext context) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    _sendMessage();
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _sub = context.read<AppState>().chat.subscribeNewMessages(widget.animalId).listen((map) {
      final m = _mapToMessage(map);
      setState(() {
        _messages.add(m);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final rows = await context.read<AppState>().chat.fetchMessages(widget.animalId);
      final list = rows.map((r) => _mapToMessage(r)).toList();
      setState(() {
        _messages.clear();
        _messages.addAll(list);
      });
    } catch (e) {
      setState(() {});
    }
  }

  Message _mapToMessage(Map<String, dynamic> r) {
    return Message(
      id: (r['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      from: (r['from_role'] ?? (r['user_id'] != null ? 'user' : 'org')).toString(),
      text: (r['content'] ?? '').toString(),
      sentAt: r['created_at'] != null ? DateTime.parse(r['created_at'].toString()) : DateTime.now(),
    );
  }

  Future<void> _sendMessage() async {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    try {
      await context.read<AppState>().chat.send(widget.animalId, userId ?? 'org', text);
      ctrl.clear();
      setState(() {
        _messages.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), from: userId == null ? 'org' : userId, text: text, sentAt: DateTime.now()));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar mensagem')));
    }
  }
}
