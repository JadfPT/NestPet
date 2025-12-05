import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../app_router.dart';

import '../../providers/app_state.dart';
import '../../data/animal_repository.dart';
import '../../models/animal.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/storage_repository.dart';
import '../../utils/color_tags.dart';


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
  String personalidade = '';
  int expectativaVidaAnos = 0;
  bool vacinado = false;
  String caracteristicas = '';
  String cor = '';
  bool _showColorChips = false;
  // controllers to preserve text across rebuilds
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _personalidadeController;
  late final TextEditingController _caracteristicasController;
  // selected color tags
  final Set<String> _selectedColors = {};
  final List<MediaItem> media = [];
  final String _animalId = const Uuid().v4();
  final _storage = StorageRepository();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: nome);
    _descricaoController = TextEditingController(text: descricao);
    _personalidadeController = TextEditingController(text: personalidade);
    _caracteristicasController = TextEditingController(text: caracteristicas);
    // no text controller for colors; selection via chips
  }

  Future<void> _pickMedia() async {
    // Require authenticated user for uploads
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor inicie sessão antes de enviar imagens.')));
      }
      return;
    }
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
      // adiciona localmente para preview imediato
      media.add(MediaItem(path: stored, type: type));
      // tenta fazer upload para Supabase (coloca em animals/<animalId>/<filename>)
      final filename = stored.split(Platform.pathSeparator).last;
      final dest = 'animals/$_animalId/$filename';
      try {
        final url = await _storage.uploadAnimalImage(File(stored), dest);
        // substitui o caminho local pelo URL público para uso posterior
        final idx = media.indexWhere((m) => m.path == stored);
        if (idx != -1) media[idx].path = url;
      } catch (e, st) {
        // falhou upload, mantém local path e mostra aviso mais informativo
        // ignore: avoid_print
        print('upload failed: $e');
        // ignore: avoid_print
        print(st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao subir imagem: ${e.toString()} — será guardada localmente')));
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _removeMedia(int i) {
    media.removeAt(i);
    setState(() {});
  }

  Future<void> _save() async {
    // read from controllers to build the model
    nome = _nomeController.text.trim();
    descricao = _descricaoController.text.trim();
    personalidade = _personalidadeController.text.trim();
    caracteristicas = _caracteristicasController.text.trim();
    // persist selected tags as comma-separated string
    cor = _selectedColors.join(',');
    if (media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adiciona pelo menos uma foto/vídeo.')));
      return;
    }
    final app = context.read<AppState>();
    final a = Animal(
      id: const Uuid().v4(),
      nome: nome, tipo: tipo, sexo: sexo, idadeMeses: idade,
      pesoKg: peso, tamanho: tamanho, descricao: descricao,
      personalidade: personalidade, expectativaVidaAnos: expectativaVidaAnos, vacinado: vacinado,
      caracteristicas: caracteristicas, cor: cor, media: media,
    );
    await app.addAnimal(a);               // <-- notifica a UI
    if (!context.mounted) return;
    // use global router to avoid using BuildContext across async gaps
    // import at top: see app_router.dart
    router.go('/o/home');                // <-- volta para home (evita “ecrã preto”)
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
                  Expanded(child: TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome'))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(initialValue: tipo, items: const [
                    DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                    DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                  ], onChanged: (v)=> setState(()=> tipo=v!), decoration: const InputDecoration(labelText: 'Tipo'))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField(initialValue: sexo, items: const [
                    DropdownMenuItem(value: 'M', child: Text('Macho')),
                    DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                  ], onChanged: (v)=> setState(()=> sexo=v!), decoration: const InputDecoration(labelText: 'Sexo'))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField(initialValue: tamanho, items: const [
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
              TextFormField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3),
              const SizedBox(height: 12),
              TextFormField(controller: _personalidadeController, decoration: const InputDecoration(labelText: 'Personalidade')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Expectativa de vida (anos): $expectativaVidaAnos'),
                    Slider(value: expectativaVidaAnos.toDouble(), min: 0, max: 30, divisions: 30, onChanged: (v)=> setState(()=> expectativaVidaAnos=v.round())),
                  ])),
                  const SizedBox(width: 8),
                  Column(children: [
                    const Text('Vacinado'),
                    Checkbox(value: vacinado, onChanged: (v)=> setState(()=> vacinado = v ?? false)),
                  ]),
                ],
              ),
              TextFormField(controller: _caracteristicasController, decoration: const InputDecoration(labelText: 'Características'), maxLines: 2),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text('Cores')),
                  IconButton(
                    icon: Icon(_showColorChips ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _showColorChips = !_showColorChips),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_showColorChips)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCommonColorTags.map((tag) {
                    final selected = _selectedColors.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedColors.add(tag);
                        } else {
                          _selectedColors.remove(tag);
                        }
                      }),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(_selectedColors.isEmpty ? 'Nenhuma selecionada' : 'Selecionadas: ${_selectedColors.take(3).join(', ')}${_selectedColors.length>3? ' +${_selectedColors.length-3}':''}'),
                ),
              const SizedBox(height: 8),
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
                              ? (m.path.startsWith('http') ? Image.network(m.path, fit: BoxFit.cover) : Image.file(File(m.path), fit: BoxFit.cover))
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

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _personalidadeController.dispose();
    _caracteristicasController.dispose();
    super.dispose();
  }
}
