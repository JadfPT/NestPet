// Propósito geral: Widget para escolher/alterar o avatar do utilizador a partir da
// galeria ou câmara, mostrar pré-visualização local e emitir o ficheiro selecionado.
// Observações:
// - Usa image_picker; requer permissões adequadas configuradas no projeto.
// - Suporta limpar/remover avatar e mostrar iniciais quando não há imagem.
// - Emite o ficheiro via callback 'onImage'; o armazenamento/upload é responsabilidade externa.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Widget principal com estado para gerir a seleção e pré-visualização do avatar.
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
  // Instância do image_picker e caminho de pré-visualização local.
  final ImagePicker _picker = ImagePicker();
  String? _previewPath;

  // Mostra folha modal com opções: galeria, câmara, remover ou cancelar.
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
    // Trata resultado: cancelar, remover ou avançar para seleção.
    if (res == null) return;
    if (res == -1) return;
    if (res == 2) {
      setState(() => _previewPath = null);
      widget.onImage?.call(null);
      return;
    }

    XFile? picked;
    try {
      // Escolha de imagem consoante opção: galeria ou câmara.
      if (res == 0) picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (res == 1) picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    } catch (e) {
      // ignorar
    }
    if (picked == null) return;
    // Atualiza pré-visualização e emite ficheiro selecionado.
    final file = File(picked.path);
    setState(() => _previewPath = file.path);
    widget.onImage?.call(file);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius;
    // Define provider de imagem: primeiro pré-visualização local, senão URL remota, senão null.
    final imageProvider = _previewPath != null
      ? FileImage(File(_previewPath!))
      : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty ? NetworkImage(widget.imageUrl!) : null);

    return GestureDetector(
      // Tocar no avatar abre o seletor de opções.
      onTap: _showPicker,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Avatar circular: mostra imagem se existir, caso contrário inicial.
          CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundImage: imageProvider as ImageProvider?,
            child: imageProvider == null ? Text(widget.initials.isNotEmpty ? widget.initials[0].toUpperCase() : 'U', style: TextStyle(fontSize: radius * 0.6, color: Theme.of(context).colorScheme.primary)) : null,
          ),
          // Ícone de edição por cima para indicar ação disponível.
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
