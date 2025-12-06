import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import '../widgets/empty_state.dart';
import '../../models/animal.dart';
// org screens do not use the user filters sheet

class MyAnimalsScreen extends StatefulWidget {
  const MyAnimalsScreen({super.key});

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  OverlayEntry? _fabOverlay;
  double? _lastFabBottomInset;
  // orgs don't use filters here
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _insertFabOverlay();
    });
  }

  void _insertFabOverlay() {
    final overlay = Overlay.of(context);
    final bottomInsetRaw = MediaQuery.of(context).viewPadding.bottom;
    // Use full safe-area inset with a small minimum to match earlier layout
    final bottomInset = math.max(bottomInsetRaw, 16.0);
    // If inset didn't change and overlay exists, keep it
    if (_fabOverlay != null && _lastFabBottomInset == bottomInset) return;

    // If overlay exists but inset changed, remove it so we can recreate in new position
    _fabOverlay?.remove();

    _fabOverlay = OverlayEntry(builder: (ctx) {
      final bottomInsetRaw = MediaQuery.of(context).viewPadding.bottom;
      final bottomInset = math.max(bottomInsetRaw, 16.0);
      final primary = Theme.of(context).colorScheme.primary;
      // constants removed; use inline sizes

      // compute pill bottom (distance from bottom) — matches pill Positioned(bottom: bottomInset + 8)
      final pillBottom = bottomInset + 8;
      // place the FAB so it slightly overlaps the pill (closer attachment)
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
    // Re-evaluate overlay position after dependencies change (e.g. system UI, insets, auth role)
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertFabOverlay());
  }

  @override
  void dispose() {
    _fabOverlay?.remove();
    _searchController.dispose();
    super.dispose();
  }


  // No filter methods: orgs don't expose filters in this screen

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // base list and apply search query (name or descricao)
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
              // Search input with app avatar on the right (no filters for orgs)
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
                                setState(() { _query = q.trim(); });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
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

              // Title row (centered)
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

              // Content
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
                              Positioned.fill(
                                child: AnimalGridCard(
                                  animal: a,
                                  showFav: false,                    // instituição não tem favoritos
                                  onTap: () => context.push('/animal/${a.id}'),
                                ),
                              ),
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
