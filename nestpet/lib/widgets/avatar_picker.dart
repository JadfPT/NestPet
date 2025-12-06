import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// supabase not required here (upload handled by parent)

/// Reusable avatar picker widget used by user and org edit screens.
///
/// - Shows avatar from [imageUrl] if provided, otherwise initials.
/// - Opens a bottom sheet with options: choose from gallery, take photo, remove avatar.
/// - Calls [onImage] with a File when a new image is picked, or with null when removed.
class AvatarPicker extends StatefulWidget {
  final String? imageUrl;
  final String initials;
  final ValueChanged<File?>? onImage;
  final double radius;

  const AvatarPicker({super.key, this.imageUrl, required this.initials, this.onImage, this.radius = 48});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  String? _previewPath; // local preview path while uploading

  Future<void> _showPicker() async {
    final res = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Escolher da galeria'), onTap: () => Navigator.pop(c, 0)),
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Tirar foto'), onTap: () => Navigator.pop(c, 1)),
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Remover avatar'), onTap: () => Navigator.pop(c, 2)),
          ListTile(leading: const Icon(Icons.close), title: const Text('Cancelar'), onTap: () => Navigator.pop(c, -1)),
        ]),
      ),
    );
    if (res == null) return;
    if (res == -1) return;
    if (res == 2) {
      // remove
      setState(() => _previewPath = null);
      widget.onImage?.call(null);
      return;
    }

    XFile? picked;
    try {
      if (res == 0) picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (res == 1) picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    } catch (e) {
      // ignore
    }
    if (picked == null) return;
    final file = File(picked.path);
    setState(() => _previewPath = file.path);
    widget.onImage?.call(file);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    final imageProvider = _previewPath != null
      ? FileImage(File(_previewPath!))
      : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty ? NetworkImage(widget.imageUrl!) : null);

    return GestureDetector(
      onTap: _showPicker,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundImage: imageProvider as ImageProvider?,
            child: imageProvider == null ? Text(widget.initials.isNotEmpty ? widget.initials[0].toUpperCase() : 'U', style: TextStyle(fontSize: radius * 0.6, color: Theme.of(context).colorScheme.primary)) : null,
          ),
          Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.12*255).round()), blurRadius: 4)]),
            child: Icon(Icons.edit, size: radius * 0.35, color: Colors.white),
          )
        ],
      ),
    );
  }
}
