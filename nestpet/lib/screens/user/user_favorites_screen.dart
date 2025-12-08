// Propósito geral: Ecrã de favoritos do utilizador, mostrando animais marcados como
// favoritos e permitindo navegar para o detalhe de cada um.
// Observações:
// - Usa estado de `AppState` para obter a lista atual de favoritos.
// - Mostra mensagem simples quando não existem favoritos.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';

// Stateless: renderiza grelha de favoritos ou estado vazio.
class UserFavoritesScreen extends StatelessWidget {
  const UserFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém favoritos atuais do estado da aplicação.
    final items = context.watch<AppState>().favorites();
    return Scaffold(
      // Barra superior com título estilizado.
      appBar: AppBar( title: Text('Favoritos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),),
      // Corpo: mensagem quando vazio, senão grelha de cartões.
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
                // Toque no cartão navega para detalhe do animal.
                onTap: () => context.push('/animal/${items[i].id}'),
              ),
            ),
    );
  }
}
