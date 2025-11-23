import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/message.dart';

class UserChatScreen extends StatefulWidget {
  final String animalId;
  const UserChatScreen({super.key, required this.animalId});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final ctrl = TextEditingController();
  final List<Message> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  Widget build(BuildContext context) {
    final msgs = _messages;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                final isMe = m.from == 'user';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Escrever...'))),
                IconButton(
                  onPressed: () {
                    _sendMessage();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(list);
      });
    } catch (e) {
      setState(() {});
    }
  }

  Message _mapToMessage(Map<String, dynamic> r) {
    final id = (r['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    String from;
    if (r['from_role'] != null) {
      from = r['from_role'].toString();
    } else if (r['user_id'] != null) {
      from = 'user';
    } else {
      from = 'org';
    }
    final text = (r['content'] ?? '').toString();
    final sentAt = r['created_at'] != null ? DateTime.parse(r['created_at'].toString()) : DateTime.now();
    return Message(id: id, from: from, text: text, sentAt: sentAt);
  }

  Future<void> _sendMessage() async {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    try {
      await context.read<AppState>().chat.send(widget.animalId, userId ?? 'anonymous', text);
      ctrl.clear();
      // optimistic add
      setState(() {
        _messages.add(Message(id: DateTime.now().millisecondsSinceEpoch.toString(), from: userId ?? 'user', text: text, sentAt: DateTime.now()));
      });
    } catch (e) {
      // show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar mensagem')));
      }
    }
  }
}
