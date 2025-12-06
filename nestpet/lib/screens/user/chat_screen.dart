// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/message.dart';

class UserChatScreen extends StatefulWidget {
  final String animalId;
  final String? userId;
  const UserChatScreen({super.key, required this.animalId, this.userId});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final ctrl = TextEditingController();
  final List<Message> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _sub;
  final ScrollController _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _otherTyping = false;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  Timer? _typingTimer;

  @override
  Widget build(BuildContext context) {
    final msgs = _messages;
    const bg = Color(0xFFF2E8D7);
    const brand = Color(0xFF824822);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: brand,
        foregroundColor: Colors.white,
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
                final isMe = m.from == 'user';
                // bubble styles: org (left) = outlined light bubble with brown text; user (right) = filled brown bubble with white text
                final bubble = Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? brand : bg,
                    borderRadius: BorderRadius.circular(16),
                    border: isMe ? null : Border.all(color: brand, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.text,
                        style: TextStyle(color: isMe ? Colors.white : brand, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: isMe ? Colors.white70 : brand.withAlpha((0.8*255).round()), fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          if (m.from == 'user')
                            Icon(
                              m.isRead ? Icons.done_all : Icons.check,
                              size: 14,
                              color: isMe ? Colors.white70 : brand.withAlpha((0.8*255).round()),
                            ),
                        ],
                      ),
                    ],
                  ),
                );

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: bubble,
                );
              },
            ),
          ),
          // input area: use SafeArea so it sits above system navigation bar
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
                        decoration: const InputDecoration.collapsed(hintText: 'Mensagem', hintStyle: TextStyle(color: Colors.white70)),
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (s) {
                          final authUser = Supabase.instance.client.auth.currentUser;
                          final authId = authUser?.id;
                          final humanId = widget.userId ?? authId;
                          if (humanId != null) {
                            context.read<AppState>().chat.sendTypingEventUpsert(widget.animalId, humanId, true);
                            _typingTimer?.cancel();
                            _typingTimer = Timer(const Duration(seconds: 2), () {
                              context.read<AppState>().chat.sendTypingEventUpsert(widget.animalId, humanId, false);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded),
                              color: brand,
                              onPressed: _sendMessage,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          // typing indicator
          if (_otherTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('A instituição está a escrever...', style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await _loadMessages();
    final authUser = Supabase.instance.client.auth.currentUser;
    // prefer explicit route param userId (human participant) when provided; otherwise use authenticated user id
    final participantUserId = widget.userId ?? authUser?.id;
    DateTime? lastSeen;
    if (_messages.isNotEmpty) {
      lastSeen = _messages.last.sentAt.toUtc();
    } else {
      // no local messages loaded yet — ask subscription to return history
      lastSeen = null;
    }

    _sub = context.read<AppState>().chat.subscribeNewMessages(widget.animalId, userId: participantUserId, lastSeen: lastSeen).listen((map) {
      final m = _mapToMessage(map);
      _addOrUpdateMessage(m);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      if (participantUserId != null) {
        context.read<AppState>().chat.markConversationRead(widget.animalId, participantUserId);
      }
    });

    if (participantUserId != null) {
      // subscribe to typing events for the human participant so we see when the other side (org) reports typing
      _typingSub = context.read<AppState>().chat.subscribeTypingEvents(widget.animalId, participantUserId).listen((map) {
        try {
          final isTyping = (map['is_typing'] ?? false) as bool;
          setState(() {
            _otherTyping = isTyping;
          });
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 5), () {
            setState(() {
              _otherTyping = false;
            });
          });
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollCtrl.dispose();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      final participantUserId = widget.userId ?? authUser?.id;
      final rows = await context.read<AppState>().chat.fetchMessages(widget.animalId, userId: participantUserId);
      final list = rows.map((r) => _mapToMessage(r)).toList();
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _messages.addAll(list);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() {});
    }
  }

  void _addOrUpdateMessage(Message m) {
    if (!mounted) return;
    setState(() {
      // if exists, update fields (e.g., readAt)
      final idx = _messages.indexWhere((e) => e.id == m.id);
      if (idx >= 0) {
        _messages[idx] = m;
      } else {
        _messages.add(m);
      }
      // sort chronologically by sentAt, then by id to ensure stable order
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
      setState(() {
        _isSending = true;
      });
      await context.read<AppState>().chat.send(widget.animalId, userId ?? 'anonymous', text, humanUserId: userId, fromRole: 'user');
      ctrl.clear();
      // rely on subscription to deliver the saved message from server to avoid duplicates
      setState(() {
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      // show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar mensagem')));
      }
    }
  }

  void _scrollToBottom() {
    try {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
  }
}
