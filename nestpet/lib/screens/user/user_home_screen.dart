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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar (styled)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Theme.of(context).colorScheme.primary.withOpacity(0.9)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration.collapsed(
                                hintText: 'Pesquisar',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                              ),
                              onChanged: (q) {
                                // TODO: implement client-side search if desired
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // small avatar / logo on right
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Image.asset('lib/assets/NestPet_logo.png', width: 20, height: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Animais disponíveis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
                  IconButton(
                    onPressed: _openFilters,
                    icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhum animal encontrado',
                        message: 'Tenta ajustar os filtros ou volta a tentar mais tarde.',
                        actionText: 'Limpar filtros',
                        onAction: () => setState(() { tipo = null; tamanho = null; idadeMax = null; }),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final a = items[i];
                          return AnimalGridCard(
                            animal: a,
                            onTap: () => context.push('/animal/${a.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
