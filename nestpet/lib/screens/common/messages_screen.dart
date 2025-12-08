/*
Propósito: Ecrã de mensagens que lista conversas (utilizador ↔ instituição).
- Mostra últimas mensagens por conversa e permite abrir o chat correspondente.
- Adapta comportamento consoante o papel (utilizador ou instituição).

Observações:
- Usa Supabase para consultar mensagens/animais e `AppState` para nomes.
- Ordena conversas pela data da última mensagem (mais recente primeiro).
- Navegação com GoRouter para o ecrã de chat correto.
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';

// Ecrã principal de lista de conversas.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

// Modelo simples de conversa para UI.
class _Conversation {
  final String animalId;
  final String userId;
  final String animalName;
  final String lastMessage;
  final DateTime lastAt;

  _Conversation({required this.animalId, required this.userId, required this.animalName, required this.lastMessage, required this.lastAt});
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Cliente Supabase e estado local.
  final _client = Supabase.instance.client;
  List<_Conversation> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Carrega conversas ao iniciar.
    _loadConversations();
  }

  // Consulta conversas com base no papel: user vê por animal; org vê por animais da org.
  Future<void> _loadConversations() async {
    setState(() { _loading = true; _list = []; });
    final app = context.read<AppState>();
    final role = app.role;
    final sessionUser = _client.auth.currentUser;
    final me = sessionUser?.id;
    if (me == null) {
      setState(() { _loading = false; });
      return;
    }

    try {
      if (role == UserRole.user) {
        // Recolhe ids de animais envolvidos nas mensagens do utilizador.
        final rows = await _client.from('messages').select('animal_id').eq('user_id', me);
        final ids = <String>{};
        for (final r in (rows as List)) {
          final a = (r['animal_id'] ?? '').toString();
          if (a.isNotEmpty) ids.add(a);
        }

        final List<_Conversation> out = [];
        for (final aid in ids) {
          // Busca última mensagem da conversa (animal + utilizador).
          final last = await _client.from('messages').select().eq('animal_id', aid).eq('user_id', me).order('created_at', ascending: false).limit(1).maybeSingle();
          final animal = await app.animals.byId(aid);
          if (last == null) continue;
          final text = (last['content'] ?? '').toString();
          final at = last['created_at'] != null ? DateTime.parse(last['created_at'].toString()) : DateTime.now();
          out.add(_Conversation(animalId: aid, userId: me, animalName: animal?.nome ?? 'Animal', lastMessage: text, lastAt: at));
        }
        // Ordena por mais recente.
        out.sort((a,b)=>b.lastAt.compareTo(a.lastAt));
        setState((){ _list = out; _loading = false; });
        return;
      }

      if (role == UserRole.org) {
        // Obtém os animais da instituição.
        final animalsRows = await _client.from('animals').select('id').eq('org_id', me);
        final animalIds = <String>[];
        for (final r in (animalsRows as List)) {
          final a = (r['id'] ?? '').toString();
          if (a.isNotEmpty) animalIds.add(a);
        }

        final List<_Conversation> out = [];
        for (final aid in animalIds) {
          // Para cada animal, recolhe todos os utilizadores com mensagens.
          final rows = await _client.from('messages').select('user_id').eq('animal_id', aid);
          final users = <String>{};
          for (final r in (rows as List)) {
            final u = (r['user_id'] ?? '').toString();
            if (u.isNotEmpty) users.add(u);
          }
          // Para cada utilizador, pega na última mensagem com esse animal.
          for (final uid in users) {
            final last = await _client.from('messages').select().eq('animal_id', aid).eq('user_id', uid).order('created_at', ascending: false).limit(1).maybeSingle();
            final animal = await app.animals.byId(aid);
            if (last == null) continue;
            final text = (last['content'] ?? '').toString();
            final at = last['created_at'] != null ? DateTime.parse(last['created_at'].toString()) : DateTime.now();
            out.add(_Conversation(animalId: aid, userId: uid, animalName: animal?.nome ?? 'Animal', lastMessage: text, lastAt: at));
          }
        }
        // Ordena por mais recente.
        out.sort((a,b)=>b.lastAt.compareTo(a.lastAt));
        setState((){ _list = out; _loading = false; });
        return;
      }
    } catch (e) {
      // ignorar
    }

    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2E8D7);
    const brand = Color(0xFF824822);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: brand,
        foregroundColor: bg,
        elevation: 0,
        centerTitle: true,
        // Botão de voltar que respeita o papel actual.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final role = context.read<AppState>().role;
            if (role == UserRole.org) {
              context.go('/o/home');
            } else {
              context.go('/u/home');
            }
          },
        ),
        title: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF2E8D7))),
      ),
      body: _loading
          // Indicador de carregamento.
          ? const Center(child: CircularProgressIndicator())
          // Estado vazio.
          : _list.isEmpty
              ? const Center(child: Text('Sem conversas ainda'))
              // Lista de conversas com separadores.
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final c = _list[i];
                    return InkWell(
                      // Abre o chat correcto consoante papel.
                      onTap: () {
                        final role = context.read<AppState>().role;
                        if (role == UserRole.org) {
                          context.push('/org/chat/${c.animalId}/${c.userId}');
                        } else {
                          context.push('/chat/${c.animalId}/${c.userId}');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Avatar circular simples.
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: brand,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.06*255).round()), blurRadius: 4)],
                              ),
                              child: Center(child: Icon(Icons.person, color: bg)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nome do animal e pré-visualização da última mensagem.
                                  Text(c.animalName, style: const TextStyle(color: Color(0xFF824822), fontWeight: FontWeight.w700, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.done_all, size: 16, color: brand.withAlpha((0.9*255).round())),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Hora formatada da última mensagem.
                            Text(TimeOfDay.fromDateTime(c.lastAt).format(context), style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
