import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';

class UserFavoritesScreen extends StatelessWidget {
  const UserFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppState>().favorites();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: items.isEmpty
          ? const Center(child: Text('Sem favoritos por agora.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
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
