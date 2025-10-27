import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/app_state.dart';
import '../../models/animal.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String id;
  const AnimalDetailScreen({super.key, required this.id});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final Animal animal = app.animals.byId(widget.id)!;
    final isFav = app.isFav(animal.id);
    final isOrg = app.role == UserRole.org;

    Widget gallery() {
      if (animal.media.isEmpty) {
        return const SizedBox(height: 280, child: ColoredBox(color: Colors.black12));
      }
      return SizedBox(
        height: 280,
        child: PageView.builder(
          itemCount: animal.media.length,
          itemBuilder: (_, i) {
            final m = animal.media[i];
            if (m.type == 'image') return Image.file(File(m.path), fit: BoxFit.cover);
            return _InlineVideo(path: m.path);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(animal.nome),
        actions: [
          if (!isOrg)
            IconButton(
              tooltip: isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: () => app.toggleFav(animal.id),
            ),
          if (isOrg) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/o/edit/${animal.id}'), // <- GO, não push
            ),
            IconButton(
              tooltip: 'Apagar',
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Apagar animal'),
                    content: const Text('Tens a certeza? Esta ação é irreversível.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
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
      body: ListView(
        children: [
          gallery(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${animal.tipo} • ${animal.sexo} • ${animal.tamanho}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('${animal.idadeMeses} meses • ${animal.pesoKg} kg'),
                const SizedBox(height: 12),
                Text(animal.descricao),
                const SizedBox(height: 20),
                if (!isOrg)
                  FilledButton.icon(
                    onPressed: () => context.push('/chat/${animal.id}'),
                    icon: const Icon(Icons.chat),
                    label: const Text('Contactar instituição'),
                  ),
              ],
            ),
          ),
        ],
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
    _c = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _c..setLooping(true)..setVolume(0)..play();
      });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) {
      return const SizedBox(height: 280, child: ColoredBox(color: Colors.black12));
    }
    return AspectRatio(
      aspectRatio: _c.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_c),
          Positioned(
            bottom: 8, right: 8,
            child: IconButton.filledTonal(
              onPressed: () => _c.value.isPlaying ? _c.pause() : _c.play(),
              icon: Icon(_c.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ),
        ],
      ),
    );
  }
}
