// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/app_state.dart';
import '../../models/animal.dart';
import '../../utils/color_tags.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String id;
  const AnimalDetailScreen({super.key, required this.id});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final Animal? animal = app.animals.byIdSync(widget.id);

    if (animal == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final app2 = Provider.of<AppState>(context, listen: false);
        await app2.animals.byId(widget.id);
        if (mounted) setState(() {});
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFav = app.isFav(animal.id);
    final isOrg = app.role == UserRole.org;

    Widget buildGallery() {
      if (animal.media.isEmpty) {
        return const SizedBox(
          height: 260,
          child: ColoredBox(color: Colors.black12),
        );
      }

      return PageView.builder(
        controller: _pageController,
        itemCount: animal.media.length,
        itemBuilder: (_, index) {
          final m = animal.media[index];
          if (m.type == 'image') {
            if (m.path.startsWith('http')) {
              return Image.network(
                m.path,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Colors.black12),
              );
            }
            return Image.file(File(m.path), fit: BoxFit.cover);
          }
          return _InlineVideo(path: m.path);
        },
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final surface = colorScheme.surface;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          if (!isOrg)
            IconButton(
              tooltip: isFav
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber.shade400 : colorScheme.onPrimary,
              ),
              onPressed: () => app.toggleFav(animal.id),
            ),
          if (isOrg) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/o/edit/${animal.id}'),
            ),
            IconButton(
              tooltip: 'Apagar',
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Apagar animal'),
                    content: const Text(
                      'Tens a certeza? Esta ação é irreversível.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Apagar'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await context.read<AppState>().deleteAnimal(animal.id);
                  if (context.mounted) router.go('/o/home');
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // IMAGEM
          Container(
            color: primary,
            child: SizedBox(
              height: 260,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildGallery(), // sem arredondado
                  ),
                  if (animal.media.length > 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _navCircleButton(
                        icon: Icons.chevron_left,
                        onTap: () {
                          final previous = _pageController.page?.round() ?? 0;
                          if (previous > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                  if (animal.media.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _navCircleButton(
                        icon: Icons.chevron_right,
                        onTap: () {
                          final current = _pageController.page?.round() ?? 0;
                          if (current < animal.media.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // DETALHES
          Expanded(
            child: Container(
              color: surface,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(context, animal, primary),
                    const SizedBox(height: 20),
                    Text(
                      'Informações',
                      style: TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (animal.descricao.trim().isNotEmpty)
                      _characteristicsList(animal.descricao)
                    else
                      const Text(
                        'Sem informações adicionais.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 80), // espaço para o botão fixo
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // BOTÃO FIXO EM BAIXO
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
              onPressed: () {
                final user = Supabase.instance.client.auth.currentUser;
                final userId = user?.id ?? '';
                context.push('/chat/${animal.id}/$userId');
              },
              child: const Text(
                'Contactar instituição',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------- Info Card --------

  Widget _buildInfoCard(
    BuildContext context,
    Animal animal,
    Color primary,
  ) {
    final accent = primary.withOpacity(0.85);

    // Campos opcionais: só usa se existirem na classe Animal.
    bool? vacinado;
    String? expVida;
    List<String> personalidade = [];

    try {
      vacinado = (animal as dynamic).vacinado as bool?;
    } catch (_) {}

    try {
      // suporte a diferentes nomes: expectativaVidaAnos, expectativaVida, life_expectancy_years
      final ev = (animal as dynamic).expectativaVidaAnos ?? (animal as dynamic).expectativaVida ?? (animal as dynamic).life_expectancy_years;
      if (ev != null) {
        if (ev is int) {
          expVida = '$ev anos';
        } else if (ev is String && ev.trim().isNotEmpty) {
          final parsed = int.tryParse(ev);
          expVida = parsed != null ? '$parsed anos' : ev;
        }
      }
    } catch (_) {}


    try {
      final dyn = (animal as dynamic).personalidade ?? (animal as dynamic).personality;
      if (dyn != null) {
        if (dyn is List) {
          personalidade = dyn.map((e) => e.toString()).toList();
        } else if (dyn is String && dyn.trim().isNotEmpty) {
          personalidade = dyn
              .split(RegExp(r'[;,\n]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}
    String? cor;
    String? caracteristicas;
    try {
      cor = (animal as dynamic).cor as String?;
    } catch (_) {}
    try {
      caracteristicas = (animal as dynamic).caracteristicas as String?;
    } catch (_) {}

    return Card(
      color: const Color(0xFFFDF0DE),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primary.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoLine('Animal', animal.tipo, accent),
            _infoLine('Nome', animal.nome, accent),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _infoLine('Sexo', animal.sexo, accent),
                ),
                Expanded(
                  child: _infoLine('Tamanho', animal.tamanho, accent),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _infoLine(
                    'Idade',
                    '${animal.idadeMeses} meses',
                    accent,
                  ),
                ),
                Expanded(
                  child: _infoLine(
                    'Peso',
                    '${animal.pesoKg} kg',
                    accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _infoLine(
                    'Vacinado',
                    vacinado == null
                        ? '—'
                        : (vacinado ? 'Sim' : 'Não'),
                    accent,
                  ),
                ),
                Expanded(
                  child: _infoLine(
                    'Expectativa de vida',
                    expVida ?? '—',
                    accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (caracteristicas != null && caracteristicas.trim().isNotEmpty) ...[
              Text(
                'Características:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(caracteristicas, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 6),
            ],
            if (cor == null || cor.trim().isEmpty)
              _infoLine('Cor', '—', accent)
            else
              _colorTagsRow('Cor', cor, accent),
            const SizedBox(height: 4),
            if (personalidade.isNotEmpty) ...[
              const SizedBox(height: 2),
              _personalityBlock(personalidade, accent),
            ] else
              _infoLine('Personalidade', '—', accent),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorTagsRow(String label, String? corCsv, Color accent) {
    final tags = corCsv == null || corCsv.trim().isEmpty
        ? <String>[]
        : corCsv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((t) {
                final c = colorForTag(t);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
                      const SizedBox(width: 8),
                      Text(t),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalityBlock(List<String> traits, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalidade: ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: traits
                      .map(
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: accent,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: traits
                        .map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(t),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _characteristicsList(String desc) {
    final parts = desc
        .split(RegExp(r'[\n,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.black54,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _navCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineVideo extends StatefulWidget {
  final String path;
  const _InlineVideo({required this.path});

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  late VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = widget.path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));

    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _c
        ..setLooping(true)
        ..setVolume(0)
        ..play();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) {
      return const SizedBox(
        height: 260,
        child: ColoredBox(color: Colors.black12),
      );
    }
    return AspectRatio(
      aspectRatio: _c.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_c),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton.filledTonal(
              onPressed: () =>
                  _c.value.isPlaying ? _c.pause() : _c.play(),
              icon: Icon(
                _c.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
