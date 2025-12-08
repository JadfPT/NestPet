/*
Propósito: Ecrã de chat para instituições sobre um animal específico.
- Mostra o histórico, envia mensagens e mantém subscrições em tempo real.

Observações:
- Usa `AppState.chat` para fetch, envio, subscrição e marcação como lidas.
- Garante scroll para o fim ao receber novas mensagens.
- Separa parsing de linhas da BD (`_mapToMessage`) da atualização de UI.
*/
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/message.dart';

// Ecrã de chat para a instituição com um utilizador, relativamente a um animal.
class OrgChatScreen extends StatefulWidget {
  final String animalId;
  final String userId;
  const OrgChatScreen({super.key, required this.animalId, required this.userId});

  @override
  State<OrgChatScreen> createState() => _OrgChatScreenState();
}

class _OrgChatScreenState extends State<OrgChatScreen> {
  // Controlador do campo de texto.
  final ctrl = TextEditingController();
  // Lista local de mensagens.
  final List<Message> _messages = [];
  // Subscrição de novas mensagens.
  StreamSubscription<Map<String, dynamic>>? _sub;
  // Controlador de scroll para manter a lista no fim.
  final ScrollController _scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Obtém nome do animal para o título.
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
          // Lista de mensagens com bolhas diferenciadas (org vs utilizador).
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                final isOrg = m.from == 'org';
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
                          // Indicador de lido para mensagens da instituição.
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

          SafeArea(
          // Caixa de entrada com envio e emissão de "typing".
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
        ],
      ),
    );
  }

  void _send(BuildContext context) {
  // Handler de envio que valida e delega.
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    _sendMessage();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    // Inicializa carregamento e subscrições após primeiro frame.
  }

  Future<void> _init() async {
  // Carrega mensagens e subscreve novos eventos (mensagens e typing).
    await _loadMessages();
    DateTime? lastSeen;
    if (_messages.isNotEmpty) {
      lastSeen = _messages.last.sentAt.toUtc();
    } else {
      lastSeen = null;
    }

    _sub = context.read<AppState>().chat.subscribeNewMessages(widget.animalId, userId: widget.userId, lastSeen: lastSeen).listen((map) {
      final m = _mapToMessage(map);
      _addOrUpdateMessage(m);
      WidgetsBinding.instance.addPostFrameCallback((_) {
      // Após receber, tenta rolar para o fim para ver a mensagem.
        try {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
        } catch (_) {}
      });
      context.read<AppState>().chat.markConversationRead(widget.animalId, widget.userId);
      // Marca a conversa como lida para a instituição.
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Cancela subscrições e controladores.
    _scrollCtrl.dispose();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
  // Busca histórico e atualiza lista local.
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
  // Adiciona ou atualiza uma mensagem existente e mantém ordenação.
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
  // Converte um mapa vindo da BD/evento para `Message`.
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
  // Envia a mensagem como "org" e limpa a caixa de entrada.
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id;
    try {
      await context.read<AppState>().chat.send(widget.animalId, userId ?? 'org', text, humanUserId: widget.userId, fromRole: 'org');
      ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao enviar mensagem')));
      }
    }
  }
}