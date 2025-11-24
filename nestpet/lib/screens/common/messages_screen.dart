import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: const Center(child: Text('Lista de mensagens diretas (por implementar)')),
    );
  }
}
