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
    final primary = Theme.of(context).colorScheme.primary;

    Widget media() {
      if (first == null) return const ColoredBox(color: Colors.black12);
      if (first.type == 'video') return _VideoThumb(path: first.path);
      if (first.path.startsWith('http')) {
        return Image.network(first.path, fit: BoxFit.cover, errorBuilder: (c,e,s) => const ColoredBox(color: Colors.black12));
      }
      return Image.file(File(first.path), fit: BoxFit.cover);
    }

    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            // framed image
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary, width: 2),
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: media()),
              ),
            ),

            // favorite star top-right
            if (showFav && app.role == UserRole.user)
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => app.toggleFav(animal.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                    ),
                    child: Icon(
                      fav ? Icons.star : Icons.star_border,
                      color: fav ? const Color(0xFF824822) : primary.withOpacity(0.85),
                      size: 20,
                    ),
                  ),
                ),
              ),

            // name label bottom center
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.9)),
                ),
                child: Text(animal.nome, style: TextStyle(color:Color(0xFF824822), fontWeight: FontWeight.w600)),
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
    if (widget.path.startsWith('http')) {
      _c = VideoPlayerController.networkUrl(Uri.parse(widget.path))
        ..initialize().then((_) { if (mounted) setState(() {}); _c.setVolume(0); _c.setLooping(true); _c.play(); });
    } else {
      _c = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) { if (mounted) setState(() {}); _c.setVolume(0); _c.setLooping(true); _c.play(); });
    }
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) return const ColoredBox(color: Colors.black12);
    return FittedBox(fit: BoxFit.cover, child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c)));
  }
}
