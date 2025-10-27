import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_state.dart';
import '../../data/animal_repository.dart';
import '../../models/animal.dart';
import 'package:uuid/uuid.dart';
import '../../models/animal.dart';


class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});
  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final form = GlobalKey<FormState>();
  String nome = '';
  String tipo = 'Cão';
  String sexo = 'M';
  int idade = 6;
  double peso = 5;
  String tamanho = 'médio';
  String descricao = '';
  final List<MediaItem> media = [];

  Future<void> _pickMedia() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg','jpeg','png','mp4','mov','avi'],
    );
    if (res == null) return;
    for (final f in res.files) {
      if (media.length >= 10) break;
      final path = f.path!;
      final ext = path.split('.').last.toLowerCase();
      final type = ['mp4','mov','avi'].contains(ext) ? 'video' : 'image';
      final stored = await AnimalRepository.persistPickedFile(path);
      media.add(MediaItem(path: stored, type: type));
    }
    if (mounted) setState(() {});
  }

  void _removeMedia(int i) {
    media.removeAt(i);
    setState(() {});
  }

  Future<void> _save() async {
    form.currentState?.save();
    if (media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adiciona pelo menos uma foto/vídeo.')));
      return;
    }
    final app = context.read<AppState>();
    final a = Animal(
      id: const Uuid().v4(),
      nome: nome, tipo: tipo, sexo: sexo, idadeMeses: idade,
      pesoKg: peso, tamanho: tamanho, descricao: descricao, media: media,
    );
    await app.addAnimal(a);               // <-- notifica a UI
    if (!mounted) return;
    context.go('/o/home');                // <-- volta para home (evita “ecrã preto”)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar animal')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Nome'), onSaved: (v)=> nome=v?.trim()??'')),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: tipo, items: const [
                    DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                    DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                  ], onChanged: (v)=> setState(()=> tipo=v!), decoration: const InputDecoration(labelText: 'Tipo'))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField(value: sexo, items: const [
                    DropdownMenuItem(value: 'M', child: Text('Macho')),
                    DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                  ], onChanged: (v)=> setState(()=> sexo=v!), decoration: const InputDecoration(labelText: 'Sexo'))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(value: tamanho, items: const [
                    DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                    DropdownMenuItem(value: 'médio', child: Text('Médio')),
                    DropdownMenuItem(value: 'grande', child: Text('Grande')),
                  ], onChanged: (v)=> setState(()=> tamanho=v!), decoration: const InputDecoration(labelText: 'Tamanho'))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Idade (meses): $idade'),
              Slider(value: idade.toDouble(), min: 1, max: 120, divisions: 119, onChanged: (v)=> setState(()=> idade=v.round())),
              Text('Peso (kg): ${peso.toStringAsFixed(1)}'),
              Slider(value: peso, min: 0.5, max: 60, divisions: 119, onChanged: (v)=> setState(()=> peso=double.parse(v.toStringAsFixed(1)))),
              TextFormField(decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3, onSaved: (v)=> descricao=v?.trim()??''),
              const SizedBox(height: 12),

              Row(
                children: [
                  FilledButton.icon(onPressed: media.length>=10?null:_pickMedia, icon: const Icon(Icons.add_photo_alternate), label: Text('Adicionar media (${media.length}/10)')),
                  const SizedBox(width: 8),
                  if (media.isNotEmpty) TextButton(onPressed: () { setState(() => media.clear()); }, child: const Text('Limpar')),
                ],
              ),
              const SizedBox(height: 8),
              if (media.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: media.length,
                  itemBuilder: (_, i) {
                    final m = media[i];
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
                          child: IconButton(
                            icon: const Icon(Icons.cancel, size: 20),
                            onPressed: () => _removeMedia(i),
                          ),
                        )
                      ],
                    );
                  },
                ),

              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Criar')),
            ],
          ),
        ),
      ),
    );
  }
}
