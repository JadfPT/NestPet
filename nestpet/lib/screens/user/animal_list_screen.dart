import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state.dart';
import '../widgets/animal_card.dart';

/// Ecrã simples de listagem que pode ser reutilizado noutros pontos.
/// Recebe opcionalmente parâmetros de filtragem.
class AnimalListScreen extends StatelessWidget {
  final String? tipo;
  final String? tamanho;
  final int? idadeMax;

  const AnimalListScreen({super.key, this.tipo, this.tamanho, this.idadeMax});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppState>().animals;
    final items = repo.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMax);

    return Scaffold(
      appBar: AppBar(title: const Text('Animais disponíveis')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => AnimalCard(
          animal: items[i],
          onTap: () => context.push('/animal/${items[i].id}'),
        ),
      ),
    );
  }
}
