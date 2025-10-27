import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';

class OrgProfileScreen extends StatelessWidget {
  const OrgProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Instituição')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.apartment)),
            title: Text('Nome da Instituição'),
            subtitle: Text('email@instituicao.pt'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Definições (placeholder)'),
            subtitle: Text('Morada, contactos, horários, etc.'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Apagar conta'),
            subtitle: const Text('Ação irreversível (placeholder)'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Funcionalidade por implementar')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Terminar sessão'),
            onTap: () {
              context.read<AppState>().logout();
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}
