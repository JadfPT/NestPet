import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';

class OrgChatScreen extends StatefulWidget {
  final String animalId; // conversa referente a um animal
  const OrgChatScreen({super.key, required this.animalId});

  @override
  State<OrgChatScreen> createState() => _OrgChatScreenState();
}

class _OrgChatScreenState extends State<OrgChatScreen> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final animal = app.animals.byId(widget.animalId);
    final msgs = app.chat.forAnimal(widget.animalId);

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
    context.read<AppState>().chat.send(widget.animalId, 'org', text);
    ctrl.clear();
    setState(() {});
  }
}
