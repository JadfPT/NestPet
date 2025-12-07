// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../providers/app_state.dart';
import '../../models/animal.dart';
import '../../utils/color_tags.dart';
import '../../utils/personality_tags.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String id;
  const AnimalDetailScreen({super.key, required this.id});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late final PageController _pageController;
  bool _showAllPersonalities = false;
  bool _showAllColors = false;

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
                errorBuilder: (context, error, stackTrace) =>
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
              onPressed: () {
                if (app.isGuest) {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Criar conta'),
                      content: const Text('Para adicionar favoritos, precisa de criar uma conta.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                        FilledButton(onPressed: () { Navigator.pop(dialogContext); context.go('/register/user'); }, child: const Text('Criar conta')),
                      ],
                    ),
                  );
                } else {
                  app.toggleFav(animal.id);
                }
              },
            ),
          if (isOrg) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/o/edit/${animal.id}'),
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
                      'Tem a certeza? Esta ação é irreversível.',
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
                  if (context.mounted) context.go('/o/home');
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
                      'Descrição',
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
                        'Sem descrição.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      'Informações Adicionais',
                      style: TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<dynamic>(
                      future: () async {
                        try {
                          // Get org_id from animals table (animal model doesn't store it)
                          final row = await Supabase.instance.client.from('animals').select('org_id').eq('id', animal.id).maybeSingle();
                          if (row == null) return null;
                          final orgId = row['org_id'];
                          if (orgId == null) return null;
                          final org = await Supabase.instance.client.from('organizations').select().eq('user_id', orgId).maybeSingle();
                          return org;
                        } catch (_) {
                          return null;
                        }
                      }(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const SizedBox.shrink();
                        }
                        final org = snap.data;
                        if (org == null) {
                          return const Text('Sem informações da instituição.', style: TextStyle(color: Colors.black54));
                        }
                        final address = (org['address'] ?? org['morada'] ?? '') as String? ?? '';
                        final hours = (org['hours'] ?? org['horario'] ?? org['service_hours'] ?? '') as String? ?? '';
                        final phone = (org['phone'] ?? org['contacts'] ?? org['contact'] ?? '') as String? ?? '';
                        final contactEmail = (org['contact_email'] ?? org['email'] ?? '') as String? ?? '';
                        final website = (org['website'] ?? '') as String? ?? '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (address.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () async {
                                  final encoded = Uri.encodeComponent(address);
                                  final url = 'https://www.google.com/maps/search/?api=1&query=$encoded';
                                  try {
                                    await launchUrlString(url);
                                  } catch (_) {}
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, size: 18, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(address, style: const TextStyle(decoration: TextDecoration.underline))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (hours.isNotEmpty) ...[
                              Row(children: [const Icon(Icons.access_time, size: 18, color: Colors.black54), const SizedBox(width: 8), Expanded(child: Text(hours))]),
                              const SizedBox(height: 8),
                            ],
                            if (phone.isNotEmpty) ...[
                              Row(children: [const Icon(Icons.phone, size: 18, color: Colors.black54), const SizedBox(width: 8), Expanded(child: Text(phone))]),
                              const SizedBox(height: 8),
                            ],
                            if (contactEmail.isNotEmpty) ...[
                              Row(children: [const Icon(Icons.email, size: 18, color: Colors.black54), const SizedBox(width: 8), Expanded(child: Text(contactEmail))]),
                              const SizedBox(height: 8),
                            ],
                            if (website.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () async {
                                  var url = website.trim();
                                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                                    url = 'https://$url';
                                  }
                                  try {
                                    await launchUrlString(url);
                                  } catch (_) {}
                                },
                                child: Row(children: [const Icon(Icons.link, size: 18, color: Colors.black54), const SizedBox(width: 8), Expanded(child: Text(website, style: const TextStyle(decoration: TextDecoration.underline)))]),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                    SizedBox(height: isOrg ? 24 : 80), // espaço para o botão fixo (apenas quando há botão)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // BOTÃO FIXO EM BAIXO
      bottomNavigationBar: isOrg
          ? null
          : SafeArea(
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
                      if (user == null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Criar conta'),
                            content: const Text('Para contactar a instituição, precisa de criar uma conta.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                              FilledButton(onPressed: () { Navigator.pop(context); context.go('/register/user'); }, child: const Text('Criar conta')),
                            ],
                          ),
                        );
                      } else {
                        final userId = user.id;
                        context.push('/chat/${animal.id}/$userId');
                      }
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
    final accent = primary.withAlpha((0.85*255).round());

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

    final facts = [
      _Fact(label: 'Animal', value: animal.tipo),
      _Fact(label: 'Nome', value: animal.nome),
      _Fact(label: 'Sexo', value: animal.sexo),
      _Fact(label: 'Tamanho', value: animal.tamanho),
      _Fact(label: 'Idade', value: '${animal.idadeMeses} meses'),
      _Fact(label: 'Peso', value: '${animal.pesoKg.toStringAsFixed(1)} kg'),
      _Fact(label: 'Expectativa de vida', value: expVida ?? '—'),
      _Fact(label: 'Vacinado', value: vacinado == null ? '—' : (vacinado ? 'Sim' : 'Não')),
    ];

    return Card(
      color: const Color(0xFFFDF0DE),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primary.withAlpha((0.5*255).round())),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalhes', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _factGrid(facts, accent),

            if (caracteristicas != null && caracteristicas.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Características', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(caracteristicas, style: const TextStyle(color: Colors.black87)),
            ],

            const SizedBox(height: 12),
            Text('Cor', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (cor == null || cor.trim().isEmpty)
              _mutedText('—')
            else
              _colorTagsRowStyled(cor, accent),

            const SizedBox(height: 12),
            Text('Personalidade', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (personalidade.isNotEmpty)
              _personalityTagsRow(personalidade, accent)
            else
              _mutedText('—'),
          ],
        ),
      ),
    );
  }



  Widget _personalityTagsRow(List<String> personalities, Color accent) {
    final displayedPersonalities = _showAllPersonalities ? personalities : personalities.take(3).toList();
    final hasMore = personalities.length > 3;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: displayedPersonalities.map((p) {
              final c = colorForPersonality(p);
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
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(p),
                  ],
                ),
              );
            }).toList(),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => setState(() => _showAllPersonalities = !_showAllPersonalities),
                child: Text(
                  _showAllPersonalities ? 'Ocultar' : '+${personalities.length - 3} mais',
                  style: const TextStyle(
                    color: Color(0xFF824822),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorTagsRowStyled(String? corCsv, Color accent) {
    final tags = corCsv == null || corCsv.trim().isEmpty
        ? <String>[]
        : corCsv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    final displayedTags = _showAllColors ? tags : tags.take(3).toList();
    final hasMore = tags.length > 3;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: displayedTags.map((t) {
              final c = colorForTag(t);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t,
                      style: TextStyle(
                        color: c,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => setState(() => _showAllColors = !_showAllColors),
                child: Text(
                  _showAllColors ? 'Ocultar' : '+${tags.length - 3} mais',
                  style: const TextStyle(
                    color: Color(0xFF824822),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _factGrid(List<_Fact> facts, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: facts.map((f) => SizedBox(width: colWidth, child: _factTile(f, accent))).toList(),
        );
      },
    );
  }

  Widget _factTile(_Fact fact, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(fact.value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _mutedText(String text) => Text(text, style: TextStyle(color: Colors.black54));
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
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2E8D7),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _c.value.isPlaying ? _c.pause() : _c.play();
                  });
                },
                icon: Icon(
                  _c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFF824822),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact {
  final String label;
  final String value;
  _Fact({required this.label, required this.value});
}
