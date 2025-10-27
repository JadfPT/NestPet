import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Utilizador'),
            subtitle: Text('utilizador@nests.pt'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ajuda por implementar')),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Apagar conta'),
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
