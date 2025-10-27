import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../data/animal_repository.dart';
import '../../models/animal.dart';

class EditAnimalScreen extends StatefulWidget {
  final String id;
  const EditAnimalScreen({super.key, required this.id});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final form = GlobalKey<FormState>();
  late Animal a;

  @override
  void initState() {
    super.initState();
    a = context.read<AppState>().animals.byId(widget.id)!;
  }

  Future<void> _pickMedia() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','mp4','mov','avi']);
    if (res == null) return;
    for (final f in res.files) {
      if (a.media.length >= 10) break;
      final path = f.path!;
      final ext = path.split('.').last.toLowerCase();
      final type = ['mp4','mov','avi'].contains(ext) ? 'video' : 'image';
      final stored = await AnimalRepository.persistPickedFile(path);
      a.media.add(MediaItem(path: stored, type: type));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar animal')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(initialValue: a.nome, decoration: const InputDecoration(labelText: 'Nome'), onSaved: (v)=> a.nome=v?.trim()??a.nome),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField(value: a.tipo, items: const [
                  DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                  DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                ], onChanged: (v)=> setState(()=> a.tipo=v! ), decoration: const InputDecoration(labelText: 'Tipo'))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField(value: a.sexo, items: const [
                  DropdownMenuItem(value: 'M', child: Text('Macho')),
                  DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                ], onChanged: (v)=> setState(()=> a.sexo=v! ), decoration: const InputDecoration(labelText: 'Sexo'))),
              ],
            ),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField(value: a.tamanho, items: const [
                  DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                  DropdownMenuItem(value: 'médio', child: Text('Médio')),
                  DropdownMenuItem(value: 'grande', child: Text('Grande')),
                ], onChanged: (v)=> setState(()=> a.tamanho=v! ), decoration: const InputDecoration(labelText: 'Tamanho'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(initialValue: a.idadeMeses.toString(), decoration: const InputDecoration(labelText: 'Idade (meses)'), keyboardType: TextInputType.number, onSaved: (v)=> a.idadeMeses=int.tryParse(v??'${a.idadeMeses}')??a.idadeMeses)),
              ],
            ),
            TextFormField(initialValue: a.pesoKg.toStringAsFixed(1), decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number, onSaved: (v)=> a.pesoKg=double.tryParse(v??'${a.pesoKg}')??a.pesoKg),
            TextFormField(initialValue: a.descricao, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3, onSaved: (v)=> a.descricao=v?.trim()??a.descricao),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(onPressed: a.media.length>=10?null:_pickMedia, icon: const Icon(Icons.add_photo_alternate), label: Text('Adicionar media (${a.media.length}/10)')),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: a.media.length,
              itemBuilder: (_, i) {
                final m = a.media[i];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.type == 'image'
                          ? Image.file(File(m.path), fit: BoxFit.cover)
                          : Container(color: Colors.black12, alignment: Alignment.center, child: const Icon(Icons.play_circle)),
                      ),
                    ),
                    Positioned(
                      right: -8, top: -8,
                      child: IconButton(icon: const Icon(Icons.cancel, size: 20), onPressed: () { setState(() { a.media.removeAt(i); }); }),
                    )
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                form.currentState?.save();
                await context.read<AppState>().updateAnimal(a);
                if (!mounted) return;
                context.go('/o/home');
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
