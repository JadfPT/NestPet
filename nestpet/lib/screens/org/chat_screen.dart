import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/message.dart';

class OrgChatScreen extends StatefulWidget {
  final String animalId; // conversa referente a um animal
  final String userId; // human user id participating in the conversation
  const OrgChatScreen({super.key, required this.animalId, required this.userId});

  @override
  State<OrgChatScreen> createState() => _OrgChatScreenState();
}

class _OrgChatScreenState extends State<OrgChatScreen> {
  final ctrl = TextEditingController();
  final List<Message> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _sub;
  final ScrollController _scrollCtrl = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  bool _userTyping = false;
  Timer? _typingTimer;

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
              controller: _scrollCtrl,
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
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(m.text)),
                            const SizedBox(width: 8),
                            if (m.from == 'org')
                              Icon(
                                m.isRead ? Icons.done_all : Icons.check,
                                size: 14,
                                color: m.isRead ? Colors.blueAccent : Colors.grey,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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
                            onChanged: (s) {
                              // report typing for the human participant so the user's UI shows the org typing
                              // write typing_status using the human participant id (widget.userId)
                              if (widget.userId.isNotEmpty) {
                                context.read<AppState>().chat.sendTypingEventUpsert(widget.animalId, widget.userId, true);
                                _typingTimer?.cancel();
                                _typingTimer = Timer(const Duration(seconds: 2), () {
                                  context.read<AppState>().chat.sendTypingEventUpsert(widget.animalId, widget.userId, false);
                                });
                              }
                            },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(context),
                ),
              ],
            ),
          ),
          if (_userTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('O utilizador está a escrever...', style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await _loadMessages();
    // lastSeen based on latest loaded message
    DateTime? lastSeen;
    if (_messages.isNotEmpty) {
      lastSeen = _messages.last.sentAt.toUtc();
    } else {
      // request full history when no local messages present
      lastSeen = null;
    }

    _sub = context.read<AppState>().chat.subscribeNewMessages(widget.animalId, userId: widget.userId, lastSeen: lastSeen).listen((map) {
      final m = _mapToMessage(map);
      _addOrUpdateMessage(m);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        } catch (_) {}
      });
      // when org views messages, mark them read
      context.read<AppState>().chat.markConversationRead(widget.animalId, widget.userId);
    });

    // subscribe to typing events from the human user so org sees when user is typing
    _typingSub = context.read<AppState>().chat.subscribeTypingEvents(widget.animalId, widget.userId).listen((map) {
      try {
        final isTyping = (map['is_typing'] ?? false) as bool;
        setState(() {
          _userTyping = isTyping;
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _scrollCtrl.dispose();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final rows = await context.read<AppState>().chat.fetchMessages(widget.animalId, userId: widget.userId);
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

  void _addOrUpdateMessage(Message m) {
    if (!mounted) return;
    setState(() {
      final idx = _messages.indexWhere((e) => e.id == m.id);
      if (idx >= 0) {
        _messages[idx] = m;
      } else {
        _messages.add(m);
      }
      _messages.sort((a, b) {
        final c = a.sentAt.compareTo(b.sentAt);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    });
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
    DateTime? readAt;
    if (r['read_at'] != null) {
      try {
        readAt = DateTime.parse(r['read_at'].toString());
      } catch (_) {}
    }
    return Message(id: id, from: from, text: text, sentAt: sentAt, readAt: readAt);
  }

  Future<void> _sendMessage() async {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    try {
      // when org sends, pass human participant id via `humanUserId` and set fromRole to 'org'
      await context.read<AppState>().chat.send(widget.animalId, userId ?? 'org', text, humanUserId: widget.userId, fromRole: 'org');
      ctrl.clear();
      // rely on subscription to append the server-saved message
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar mensagem')));
      }
    }
  }
}
