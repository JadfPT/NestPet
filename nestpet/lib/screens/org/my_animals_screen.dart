/*
Propósito: Ecrã da instituição para gerir e visualizar os seus animais.
- Mostra lista em grelha com pesquisa; permite editar/apagar anúncios.
- Inclui botão flutuante (overlay) para aceder rapidamente às mensagens.

Observações:
- Obtém animais do `AppState` e filtra localmente pelo termo de pesquisa. 
- Usa `OverlayEntry` para posicionar um botão circular acima do conteúdo.
- Navega com `GoRouter` para edição/adição e mensagens.
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import '../widgets/empty_state.dart';
import '../../models/animal.dart';

// Ecrã principal de "Os seus animais" (instituição).
class MyAnimalsScreen extends StatefulWidget {
  const MyAnimalsScreen({super.key});

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  // Entrada de overlay para o botão flutuante (acesso a mensagens).
  OverlayEntry? _fabOverlay;
  // Guarda o último padding inferior para evitar reinserções desnecessárias.
  double? _lastFabBottomInset;
  // Controlador do campo de pesquisa.
  final TextEditingController _searchController = TextEditingController();
  // Termo de pesquisa atual (minúsculas/trim aplicado na filtragem).
  String _query = '';

  // Abre as ações (editar/apagar) para um animal em folha modal.
  void _openActions(BuildContext context, Animal a) async {
    _fabOverlay?.remove();
    _fabOverlay = null;

    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Editar anúncio do animal.
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                context.push('/o/edit/${a.id}');
              },
            ),
            // Apagar anúncio do animal com feedback via SnackBar.
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

    if (mounted) {
      _insertFabOverlay();
    }
  }

  @override
  void initState() {
    super.initState();
    // Adia a inserção do overlay para após o primeiro frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFabOverlay();
    });
  }

  // Cria/insere o overlay com botão circular de mensagens ajustado ao padding inferior.
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

      // Posição vertical do botão relativa a uma pílula imaginária inferior.
      final pillBottom = bottomInset + 8;
      final desiredFabBottom = pillBottom - 24.0;

      return Positioned(
        right: 28,
        bottom: desiredFabBottom,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            // Atalho para o ecrã de mensagens.
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
    // Garante que o overlay é consistente após mudanças de dependências (ex.: tema/insets).
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertFabOverlay());
  }

  @override
  void dispose() {
    // Remove o overlay e liberta o controlador de pesquisa.
    _fabOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtém lista atual de animais e aplica filtro pelo termo de pesquisa.
    final app = context.watch<AppState>();
    final baseItems = app.animals.all();
    final items = baseItems.where((a) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final name = a.nome.toLowerCase();
        final desc = a.descricao.toLowerCase();
        if (!(name.contains(q) || desc.contains(q))) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior com pesquisa e avatar da conta.
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
                                // Atualiza termo de pesquisa e refaz filtragem.
                                setState(() { _query = q.trim(); });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                // Limpa pesquisa e resultados.
                                _searchController.clear();
                                setState(() { _query = ''; });
                              },
                              child: Icon(Icons.close, color: Theme.of(context).colorScheme.primary.withAlpha((0.7*255).round())),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar do utilizador (instituição) a partir de Supabase; fallback para ícone.
                  GestureDetector(
                    onTap: () {},
                    child: Builder(builder: (ctx) {
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
                  'Os seus animais',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Conteúdo principal: estado vazio ou grelha de animais.
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.pets,
                        title: 'Ainda não adicionou animais',
                        message: 'Adicione um animal para começar a receber contactos.',
                        actionText: 'Adicionar animal',
                        onAction: () => context.go('/o/add'),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final a = items[i];
                          return Stack(
                            children: [
                              // Cartão do animal que abre a página de detalhes ao tocar.
                              Positioned.fill(
                                child: AnimalGridCard(
                                  animal: a,
                                  showFav: false,                  
                                  onTap: () => context.push('/animal/${a.id}'),
                                ),
                              ),
                              // Botão de contexto (três pontos) para ações de editar/apagar.
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Builder(builder: (ctx) {
                                  final primary = Theme.of(ctx).colorScheme.primary;
                                  final surface = Theme.of(ctx).colorScheme.surface;
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: surface.withAlpha((0.75 * 255).round()),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: primary.withAlpha((0.9 * 255).round())),
                                    ),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _openActions(context, a),
                                      child: Center(
                                        child: Icon(
                                          Icons.more_vert,
                                          size: 18,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
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
