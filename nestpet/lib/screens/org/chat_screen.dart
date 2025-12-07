// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    const bg = Color(0xFFF2E8D7);
    const brand = Color(0xFF824822);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Chat • ${animal?.nome ?? "Animal"}'),
        backgroundColor: brand,
        foregroundColor: bg,
        elevation: 0,
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
                // left = user (outlined light), right = org (filled brand)
                final bubble = Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isOrg ? brand : bg,
                    borderRadius: BorderRadius.circular(16),
                    border: isOrg ? null : Border.all(color: brand, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.text,
                        style: TextStyle(color: isOrg ? Colors.white : brand, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: isOrg ? Colors.white70 : brand.withAlpha((0.8*255).round()), fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          if (m.from == 'org')
                            Icon(
                              m.isRead ? Icons.done_all : Icons.check,
                              size: 14,
                              color: isOrg ? Colors.white70 : brand.withAlpha((0.8*255).round()),
                            ),
                        ],
                      ),
                    ],
                  ),
                );

                return Align(
                  alignment: isOrg ? Alignment.centerRight : Alignment.centerLeft,
                  child: bubble,
                );
              },
            ),
          ),

          // input area above system nav bar
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration.collapsed(hintText: 'Responder...', hintStyle: TextStyle(color: Colors.white70)),
                        onSubmitted: (_) => _send(context),
                        onChanged: (s) {
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
                    const SizedBox(width: 8),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: brand,
                        onPressed: () => _send(context),
                      ),
                    ),
                  ],
                ),
              ),
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