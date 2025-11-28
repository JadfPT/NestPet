import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../app_router.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../data/animal_repository.dart';
import '../../models/animal.dart';
import '../../data/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final cached = context.read<AppState>().animals.byIdSync(widget.id);
    if (cached != null) {
      a = cached;
    } else {
      a = Animal(id: widget.id, nome: '', tipo: 'Cão', sexo: 'M', idadeMeses: 0, pesoKg: 0.0, tamanho: 'médio', descricao: '', media: []);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final fetched = await context.read<AppState>().animals.byId(widget.id);
        if (fetched != null && mounted) setState(() { a = fetched; });
      });
    }
  }

  Future<void> _pickMedia() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor inicie sessão antes de enviar imagens.')));
      return;
    }
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','mp4','mov','avi']);
    if (res == null) return;
    for (final f in res.files) {
      if (a.media.length >= 10) break;
      final path = f.path!;
      final ext = path.split('.').last.toLowerCase();
      final type = ['mp4','mov','avi'].contains(ext) ? 'video' : 'image';
      String stored;
      try {
        stored = await AnimalRepository.persistPickedFile(path);
      } catch (e, st) {
        // ignore: avoid_print
        print('persistPickedFile failed: $e');
        // ignore: avoid_print
        print(st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao aceder ficheiro local')));
        }
        continue;
      }
      // debug: confirmar que o ficheiro existe no caminho copiado
      // ignore: avoid_print
      print('Picked stored path: $stored (exists=${File(stored).existsSync()})');
      a.media.add(MediaItem(path: stored, type: type));
      // upload para supabase
      final filename = stored.split(Platform.pathSeparator).last;
      final dest = 'animals/${a.id}/$filename';
      try {
        final url = await StorageRepository().uploadAnimalImage(File(stored), dest);
        // substituir local path pelo url
        final idx = a.media.indexWhere((m) => m.path == stored);
        if (idx != -1) a.media[idx].path = url;
      } catch (e, st) {
        // ignore: avoid_print
        print('upload failed: $e');
        // ignore: avoid_print
        print(st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao subir imagem: ${e.toString()} — ficará local')));
        }
      }
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
                Expanded(child: DropdownButtonFormField(initialValue: a.tipo, items: const [
                  DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                  DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                ], onChanged: (v)=> setState(()=> a.tipo=v! ), decoration: const InputDecoration(labelText: 'Tipo'))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField(initialValue: a.sexo, items: const [
                  DropdownMenuItem(value: 'M', child: Text('Macho')),
                  DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                ], onChanged: (v)=> setState(()=> a.sexo=v! ), decoration: const InputDecoration(labelText: 'Sexo'))),
              ],
            ),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField(initialValue: a.tamanho, items: const [
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
            TextFormField(initialValue: a.personalidade, decoration: const InputDecoration(labelText: 'Personalidade'), onSaved: (v)=> a.personalidade=v?.trim()??a.personalidade),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Expectativa de vida (anos): ${a.expectativaVidaAnos}'),
                  Slider(value: a.expectativaVidaAnos.toDouble(), min: 0, max: 30, divisions: 30, onChanged: (v)=> setState(()=> a.expectativaVidaAnos = v.round())),
                ])),
                const SizedBox(width: 8),
                Column(children: [
                  const Text('Vacinado'),
                  Checkbox(value: a.vacinado, onChanged: (v)=> setState(()=> a.vacinado = v ?? false)),
                ]),
              ],
            ),
            TextFormField(initialValue: a.caracteristicas, decoration: const InputDecoration(labelText: 'Características'), maxLines: 2, onSaved: (v)=> a.caracteristicas=v?.trim()??a.caracteristicas),
            const SizedBox(height: 8),
            TextFormField(initialValue: a.cor, decoration: const InputDecoration(labelText: 'Cor'), onSaved: (v)=> a.cor=v?.trim()??a.cor),
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
                                ? (m.path.startsWith('http') ? Image.network(m.path, fit: BoxFit.cover, errorBuilder: (c,e,s) => const ColoredBox(color: Colors.black12)) : Image.file(File(m.path), fit: BoxFit.cover))
                                : (m.path.startsWith('http') ? Container(color: Colors.black12, alignment: Alignment.center, child: const Icon(Icons.play_circle)) : Container(color: Colors.black12, alignment: Alignment.center, child: const Icon(Icons.play_circle))),
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
                try {
                  await context.read<AppState>().updateAnimal(a);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado com sucesso')));
                  router.go('/o/home');
                } catch (e) {
                  // ignore: avoid_print
                  print('updateAnimal failed: $e');
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao guardar: ${e.toString()}')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
