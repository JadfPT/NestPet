import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
            // framed image with subtle shadow
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withAlpha((0.9*255).round()), width: 1.2),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.06*255).round()), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: media()),
              ),
            ),

            // favorite star top-right
            if (showFav && app.role == UserRole.user)
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
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
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: fav
                            ? Icon(
                                Icons.star,
                                key: const ValueKey('fav_on'),
                                color: Colors.amber.shade600,
                                size: 26,
                              )
                            : Icon(
                                Icons.star_border,
                                key: const ValueKey('fav_off'),
                                color: Colors.amber.shade600,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                ),
              ),

            // subtle gradient overlay + label for readability
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withAlpha((0.75*255).round()),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primary.withAlpha((0.9*255).round())),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          animal.nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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
