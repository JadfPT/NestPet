import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    // If inset didn't change and overlay exists, keep it
    if (_fabOverlay != null && _lastFabBottomInset == bottomInset) return;

    // If overlay exists but inset changed, remove it so we can recreate in new position
    _fabOverlay?.remove();

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
    super.dispose();
  }


  // No filter methods: orgs don't expose filters in this screen

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.animals.all();

    return Scaffold(
       appBar: AppBar(title: Text('Os seus animais', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary))),
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
                      right: 6,
                      bottom: 6,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _openActions(context, a),
                        tooltip: 'Mais ações',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
