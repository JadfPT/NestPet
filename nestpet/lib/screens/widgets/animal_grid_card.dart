import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/animal.dart';
import '../../providers/app_state.dart';
import 'package:video_player/video_player.dart';

class AnimalGridCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final bool showFav; // <= novo

  const AnimalGridCard({
    super.key,
    required this.animal,
    this.onTap,
    this.showFav = true,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fav = app.isFav(animal.id);
    final first = animal.media.isNotEmpty ? animal.media.first : null;

    Widget media() {
      if (first == null) return const ColoredBox(color: Colors.black12);
      if (first.type == 'video') return _VideoThumb(path: first.path);
      return Image.file(File(first.path), fit: BoxFit.cover);
    }

    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: media())),
            if (showFav && app.role == UserRole.user)
              Positioned(
                right: 8, top: 8,
                child: IconButton.filledTonal(
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => app.toggleFav(animal.id),
                ),
              ),
            Positioned(
              left: 8, bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(animal.nome, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumb extends StatefulWidget {
  final String path;
  const _VideoThumb({required this.path});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late VideoPlayerController _c;
  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) { if (mounted) setState(() {}); _c.setVolume(0); _c.setLooping(true); _c.play(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) return const ColoredBox(color: Colors.black12);
    return FittedBox(fit: BoxFit.cover, child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c)));
  }
}
