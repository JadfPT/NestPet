import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _Conversation {
  final String animalId;
  final String userId; // human user id
  final String animalName;
  final String lastMessage;
  final DateTime lastAt;

  _Conversation({required this.animalId, required this.userId, required this.animalName, required this.lastMessage, required this.lastAt});
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _client = Supabase.instance.client;
  List<_Conversation> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _list = []; });
    final app = context.read<AppState>();
    final role = app.role;
    final sessionUser = _client.auth.currentUser;
    final me = sessionUser?.id;
    if (me == null) {
      // not logged in
      setState(() { _loading = false; });
      return;
    }

    try {
      if (role == UserRole.user) {
        // user: conversations are distinct animal_id where messages.user_id = me
        final rows = await _client.from('messages').select('animal_id').eq('user_id', me);
        final ids = <String>{};
        for (final r in (rows as List)) {
          final a = (r['animal_id'] ?? '').toString();
          if (a.isNotEmpty) ids.add(a);
        }

        final List<_Conversation> out = [];
        for (final aid in ids) {
          final last = await _client.from('messages').select().eq('animal_id', aid).eq('user_id', me).order('created_at', ascending: false).limit(1).maybeSingle();
          final animal = await app.animals.byId(aid);
          if (last == null) continue;
          final text = (last['content'] ?? '').toString();
          final at = last['created_at'] != null ? DateTime.parse(last['created_at'].toString()) : DateTime.now();
          out.add(_Conversation(animalId: aid, userId: me, animalName: animal?.nome ?? 'Animal', lastMessage: text, lastAt: at));
        }
        out.sort((a,b)=>b.lastAt.compareTo(a.lastAt));
        setState((){ _list = out; _loading = false; });
        return;
      }

      if (role == UserRole.org) {
        // org: for each animal owned by me, find distinct human user_ids that messaged it
        final animalsRows = await _client.from('animals').select('id').eq('org_id', me);
        final animalIds = <String>[];
        for (final r in (animalsRows as List)) {
          final a = (r['id'] ?? '').toString();
          if (a.isNotEmpty) animalIds.add(a);
        }

        final List<_Conversation> out = [];
        for (final aid in animalIds) {
          final rows = await _client.from('messages').select('user_id').eq('animal_id', aid);
          final users = <String>{};
          for (final r in (rows as List)) {
            final u = (r['user_id'] ?? '').toString();
            if (u.isNotEmpty) users.add(u);
          }
          for (final uid in users) {
            final last = await _client.from('messages').select().eq('animal_id', aid).eq('user_id', uid).order('created_at', ascending: false).limit(1).maybeSingle();
            final animal = await app.animals.byId(aid);
            if (last == null) continue;
            final text = (last['content'] ?? '').toString();
            final at = last['created_at'] != null ? DateTime.parse(last['created_at'].toString()) : DateTime.now();
            out.add(_Conversation(animalId: aid, userId: uid, animalName: animal?.nome ?? 'Animal', lastMessage: text, lastAt: at));
          }
        }
        out.sort((a,b)=>b.lastAt.compareTo(a.lastAt));
        setState((){ _list = out; _loading = false; });
        return;
      }
    } catch (e) {
      // ignore errors for now
    }

    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _list.isEmpty
          ? const Center(child: Text('Sem conversas ainda'))
          : ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final c = _list[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(c.animalName),
                  subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(TimeOfDay.fromDateTime(c.lastAt).format(context)),
                  onTap: () {
                    final role = context.read<AppState>().role;
                    if (role == UserRole.org) {
                      context.push('/org/chat/${c.animalId}/${c.userId}');
                    } else {
                      context.push('/chat/${c.animalId}/${c.userId}');
                    }
                  },
                );
              },
            ),
    );
  }
}
