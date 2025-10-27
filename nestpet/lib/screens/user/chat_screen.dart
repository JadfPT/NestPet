import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class UserChatScreen extends StatefulWidget {
  final String animalId;
  const UserChatScreen({super.key, required this.animalId});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final msgs = app.chat.forAnimal(widget.animalId);
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
                      color: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
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
                    if (ctrl.text.trim().isEmpty) return;
                    app.chat.send(widget.animalId, 'user', ctrl.text.trim());
                    ctrl.clear();
                    setState(() {});
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
}
