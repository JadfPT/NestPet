import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import '../widgets/empty_state.dart';

class OrgHomeScreen extends StatelessWidget {
  const OrgHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.animals.all(); // <= substitui myAnimals()

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
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => AnimalGridCard(
                animal: items[i],
                onTap: () => context.push('/animal/${items[i].id}'),
              ),
            ),
    );
  }
}
