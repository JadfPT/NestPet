// Propósito geral: Ecrã principal para utilizadores, mostrando lista de animais disponíveis
// com pesquisa, filtros e navegação para detalhes; inclui um atalho flutuante para mensagens.
// Observações:
// - Filtragem é feita localmente sobre os dados do repositório em memória.
// - Usa Overlay para colocar o botão de chat alinhado com a barra inferior do shell.
// - A lista renderiza cartões `AnimalGridCard` e usa o router para navegar para detalhes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../providers/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/animal_grid_card.dart';
import 'animal_filters_sheet.dart';
import '../widgets/empty_state.dart';

// StatefulWidget para gerir estado de filtros, pesquisa e overlay do FAB.
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Filtros
  String? tipo;
  String? tamanho;
  int? idadeMax;
  String? sexo;
  bool? vacinado;
  String? cor;
  double? pesoMin;
  double? pesoMax;
  // Pesquisa
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  // Overlay do botão de chat
  OverlayEntry? _fabOverlay;
  double? _lastFabBottomInset;

  // Abre folha de filtros e aplica resultados.
  Future<void> _openFilters() async {
    final hadOverlay = _fabOverlay != null;
    if (hadOverlay) {
      _fabOverlay?.remove();
      _fabOverlay = null;
    }

    try {
      final res = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AnimalFiltersSheet(
          initialTipo: tipo,
          initialTamanho: tamanho,
          initialIdadeMax: idadeMax,
          initialSexo: sexo,
          initialVacinado: vacinado,
          initialCor: cor,
          initialPesoMin: pesoMin?.toDouble(),
          initialPesoMax: pesoMax?.toDouble(),
        ),
      );
      if (res != null && mounted) {
        setState(() {
          tipo = res['tipo'] as String?;
          tamanho = res['tamanho'] as String?;
          idadeMax = res['idade'] as int?;
          sexo = res['sexo'] as String?;
          vacinado = res['vacinado'] as bool?;
          cor = res['cor'] as String?;
          pesoMin = res['pesoMin'] as double?;
          pesoMax = res['pesoMax'] as double?;
        });
      }
    } finally {
      // Reinsere o overlay após fechar filtros para manter posição do FAB.
      if (hadOverlay && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _insertFabOverlay());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém repositório e lista base com filtros iniciais simples.
    final repo = context.watch<AppState>().animals;
    final baseItems = repo.list(tipo: tipo, tamanho: tamanho, idadeMaxMeses: idadeMax);
    // Aplica filtros avançados e pesquisa.
    final items = baseItems.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final name = a.nome.toLowerCase();
        final desc = a.descricao.toLowerCase();
        if (!(name.contains(q) || desc.contains(q))) return false;
      }
      if (sexo != null && sexo!.isNotEmpty && a.sexo != sexo) return false;
      if (vacinado != null && a.vacinado != vacinado) return false;
      if (cor != null && cor!.isNotEmpty) {
        final selectedColors = cor!.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
        final animalColor = a.cor.toLowerCase();
        if (!selectedColors.any((c) => animalColor.contains(c))) return false;
      }
      if (pesoMin != null && a.pesoKg < pesoMin!) return false;
      if (pesoMax != null && a.pesoKg > pesoMax!) return false;
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de topo: filtro, pesquisa e avatar do utilizador.
              Row(
                children: [
                  IconButton(
                    onPressed: _openFilters,
                    icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Filtrar',
                  ),
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
                          Icon(Icons.search, color: Theme.of(context).colorScheme.primary.withAlpha((0.9*255).round())),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration.collapsed(
                                hintText: 'Pesquisar',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withAlpha((0.6*255).round())),
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
                              child: Icon(Icons.close, color: Theme.of(context).colorScheme.primary.withAlpha((0.7*255).round())),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Builder(builder: (ctx) {
                      // Mostra avatar do utilizador se houver URL nas metadatas; caso contrário, ícone pets.
                      final user = Supabase.instance.client.auth.currentUser;
                      final meta = user?.userMetadata;
                      dynamic raw = meta != null ? meta['avatar_url'] : null;
                      String? avatarUrl;
                      if (raw is String && raw.isNotEmpty) avatarUrl = raw;
                      if (raw is List && raw.isNotEmpty) {
                        final first = raw.first;
                        if (first is String && first.isNotEmpty) avatarUrl = first;
                      }

                      if (avatarUrl != null) {
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.08*255).round()), blurRadius: 4, offset: Offset(0,2))],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundImage: NetworkImage(avatarUrl),
                          ),
                        );
                      }

                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha((0.08*255).round()), blurRadius: 4, offset: Offset(0,2)),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.pets, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Título da secção.
              Center(
                child: Text(
                  'Animais disponíveis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Lista de animais ou estado vazio com ação para limpar filtros.
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhum animal encontrado',
                        message: 'Tente ajustar os filtros ou volte a tentar mais tarde.',
                        actionText: 'Limpar filtros',
                        onAction: () => setState(() { tipo = null; tamanho = null; idadeMax = null; sexo = null; vacinado = null; cor = null; pesoMin = null; pesoMax = null; }),
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
    // Após primeiro frame, insere overlay do botão de chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFabOverlay();
    });
  }

  // Cria/insere OverlayEntry para o botão flutuante de chat, posicionado conforme insets.
  void _insertFabOverlay() {
    final overlay = Overlay.of(context);
    final bottomInsetRaw = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset = math.max(bottomInsetRaw, 16.0);
    if (_fabOverlay != null && _lastFabBottomInset == bottomInset) return;
    _fabOverlay?.remove();

    _fabOverlay = OverlayEntry(builder: (ctx) {
      final bottomInsetRaw = MediaQuery.of(context).viewPadding.bottom;
      final bottomInset = math.max(bottomInsetRaw, 16.0);
      final primary = Theme.of(context).colorScheme.primary;

      final pillBottom = bottomInset + 8;
      final desiredFabBottom = pillBottom - 24.0;

      return Positioned(
        right: 28,
        bottom: desiredFabBottom,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => context.go('/messages'),
              child: Container(
              width: 56.0,
              height: 56.0,
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
    _lastFabBottomInset = bottomInset;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reposiciona overlay quando mudanças de dependências podem afetar layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertFabOverlay());
  }

  @override
  void dispose() {
    // Limpa overlay e dispose do controlador de pesquisa.
    _fabOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }
}
