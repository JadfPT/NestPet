import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state.dart';
import '../widgets/animal_grid_card.dart';
import '../widgets/empty_state.dart';
import '../../models/animal.dart';
import '../user/animal_filters_sheet.dart';

class MyAnimalsScreen extends StatefulWidget {
  const MyAnimalsScreen({super.key});

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  OverlayEntry? _fabOverlay;
  double? _lastFabBottomInset;
  // filter state
  String? tipo;
  String? tamanho;
  int? idadeMax;
  String? sexo;
  bool? vacinado;
  String? cor;
  int? pesoMin;
  int? pesoMax;
  String? caracteristicas;

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

  Future<void> _openFilters() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AnimalFiltersSheet(
        initialTipo: tipo,
        initialTamanho: tamanho,
        initialIdadeMax: idadeMax,
        initialSexo: sexo,
        initialVacinado: vacinado,
        initialCor: cor,
        initialPesoMin: pesoMin?.toDouble(),
        initialPesoMax: pesoMax?.toDouble(),
        initialCaracteristicas: caracteristicas,
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
        pesoMin = res['pesoMin'] as int?;
        pesoMax = res['pesoMax'] as int?;
        caracteristicas = res['caracteristicas'] as String?;
      });
      // debug feedback
      // ignore: avoid_print
      print('MyAnimalsScreen: filtros aplicados: ' + res.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Filtros aplicados')));
      }
    }
  }

  void _clearFilters() {
    setState(() {
      tipo = null;
      tamanho = null;
      idadeMax = null;
      sexo = null;
      vacinado = null;
      cor = null;
      pesoMin = null;
      pesoMax = null;
      caracteristicas = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final base = app.animals.all();
    final items = base.where((a) {
      if (tipo != null && tipo!.isNotEmpty && a.tipo != tipo) return false;
      if (tamanho != null && tamanho!.isNotEmpty && a.tamanho != tamanho) return false;
      if (idadeMax != null && a.idadeMeses > idadeMax!) return false;
      if (sexo != null && sexo!.isNotEmpty && a.sexo != sexo) return false;
      if (vacinado != null && a.vacinado != vacinado) return false;
      if (cor != null && cor!.isNotEmpty && !a.cor.toLowerCase().contains(cor!.toLowerCase())) return false;
      if (pesoMin != null && a.pesoKg < pesoMin!) return false;
      if (pesoMax != null && a.pesoKg > pesoMax!) return false;
      if (caracteristicas != null && caracteristicas!.isNotEmpty) {
        final k = caracteristicas!.toLowerCase();
        final inNome = a.nome.toLowerCase().contains(k);
        final inDesc = a.descricao.toLowerCase().contains(k);
        final inCar = a.caracteristicas.toLowerCase().contains(k);
        if (!(inNome || inDesc || inCar)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
     appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.onPrimary),
          tooltip: 'Filtrar',
          onPressed: _openFilters,
        ),
        title: Text('Os seus animais', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
        actions: [
          if ([tipo, tamanho, idadeMax, sexo, vacinado, cor, pesoMin, pesoMax, caracteristicas].any((e) => e != null))
            IconButton(
              icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onPrimary),
              tooltip: 'Limpar filtros',
              onPressed: _clearFilters,
            ),
        ],
      ),
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
