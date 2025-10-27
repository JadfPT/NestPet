import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import 'animal_filters_sheet.dart';
import '../widgets/empty_state.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String? tipo;
  String? tamanho;
  int? idadeMax;

  Future<void> _openFilters() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnimalFiltersSheet(
        initialTipo: tipo,
        initialTamanho: tamanho,
        initialIdadeMax: idadeMax,
      ),
    );
    if (res != null && mounted) {
      setState(() {
        tipo = res['tipo'] as String?;
        tamanho = res['tamanho'] as String?;
        idadeMax = res['idade'] as int?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppState>().animals;
    final items = repo.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMax);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animais disponíveis'),
        actions: [
          IconButton(
            tooltip: 'Filtros',
            onPressed: _openFilters,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              title: 'Nenhum animal encontrado',
              message: 'Tenta ajustar os filtros ou volta a tentar mais tarde.',
              actionText: 'Limpar filtros',
              onAction: () => setState(() { tipo = null; tamanho = null; idadeMax = null; }),
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
