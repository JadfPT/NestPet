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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  OverlayEntry? _fabOverlay;

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
    final baseItems = repo.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMax);
    final items = baseItems.where((a) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = a.nome.toLowerCase();
      final desc = a.descricao.toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar (styled) with filter button at left and app symbol on right
              Row(
                children: [
                  // Filter button on the left
                  IconButton(
                    onPressed: _openFilters,
                    icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Filtrar',
                  ),
                  // Search input container
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
                              controller: _searchController,
                              decoration: InputDecoration.collapsed(
                                hintText: 'Pesquisar',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                              ),
                              onChanged: (q) {
                                setState(() {
                                  _query = q.trim();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                              },
                              child: Icon(Icons.close, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // App symbol on the right (outside the search box)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: Offset(0,2)),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.pets, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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
                  const SizedBox.shrink(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFabOverlay();
    });
  }

  void _insertFabOverlay() {
    if (_fabOverlay != null) return;
    final overlay = Overlay.of(context);

    _fabOverlay = OverlayEntry(builder: (ctx) {
      final bottomInset = MediaQuery.of(context).viewPadding.bottom;
      final primary = Theme.of(context).colorScheme.primary;
      const pillHeight = 58.0;
      const fabSize = 56.0;

      // small adjustable offset to tweak how far above the pill the FAB sits
      const fabVerticalAdjustment = -115; // negative -> moves FAB lower on screen

      return Positioned(
        right: 28,
        bottom: bottomInset + pillHeight + 12 + fabVerticalAdjustment,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => context.go('/messages'),
            child: Container(
              width: fabSize,
              height: fabSize,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
        ),
      );
    });

    overlay.insert(_fabOverlay!);
  }

  @override
  void dispose() {
    _fabOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }
}
