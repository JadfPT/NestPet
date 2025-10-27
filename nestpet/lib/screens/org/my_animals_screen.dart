import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import '../widgets/empty_state.dart';
import '../../models/animal.dart';

class MyAnimalsScreen extends StatelessWidget {
  const MyAnimalsScreen({super.key});

  void _openActions(BuildContext context, Animal a) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                context.push('/o/edit/${a.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Apagar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AppState>().deleteAnimal(a.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Animal apagado.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.animals.all();

    return Scaffold(
      appBar: AppBar(title: const Text('Os seus animais')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.pets,
              title: 'Ainda não adicionou animais',
              message: 'Adicione um animal para começar a receber contactos.',
              actionText: 'Adicionar animal',
              onAction: () => context.go('/o/add'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: AnimalGridCard(
                        animal: a,
                        showFav: false,                    // instituição não tem favoritos
                        onTap: () => context.push('/animal/${a.id}'),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openActions(context, a),
                        tooltip: 'Mais ações',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
