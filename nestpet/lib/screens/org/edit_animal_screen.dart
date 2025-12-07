import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../data/animal_repository.dart';
import '../../models/animal.dart';
import '../../data/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/color_tags.dart';
import '../../utils/personality_tags.dart';

class EditAnimalScreen extends StatefulWidget {
  final String id;
  const EditAnimalScreen({super.key, required this.id});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

// color chips widget removed; edit screen now manages color chips inline

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final form = GlobalKey<FormState>();
  late Animal a;
  // form state mirroring AddAnimalScreen so structure matches
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _caracteristicasController = TextEditingController();
  String tipo = 'Cão';
  String sexo = 'M';
  int idade = 6;
  double peso = 5;
  String tamanho = 'médio';
  int expectativaVidaAnos = 0;
  bool vacinado = false;
  bool _showAllPersonalities = false;
  bool _showAllColors = false;
  final Set<String> _selectedColors = {};
  final Set<String> _selectedPersonalities = {};

  @override
  void initState() {
    super.initState();
    final cached = context.read<AppState>().animals.byIdSync(widget.id);
    if (cached != null) {
      a = cached;
      // initialize controllers/state from cached
      _nomeController.text = a.nome;
      _descricaoController.text = a.descricao;
      _caracteristicasController.text = a.caracteristicas;
      tipo = a.tipo;
      sexo = a.sexo;
      idade = a.idadeMeses;
      peso = a.pesoKg <= 0.0 ? 5.0 : a.pesoKg;
      tamanho = a.tamanho;
      expectativaVidaAnos = a.expectativaVidaAnos;
      vacinado = a.vacinado;
      _selectedColors.addAll(a.cor.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
      _selectedPersonalities.addAll(a.personalidade.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
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
      appBar: AppBar(
        title: const Text('Editar animal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
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
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                ], onChanged: (v)=> setState(()=> tipo=v! ), decoration: const InputDecoration(labelText: 'Tipo'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(initialValue: tamanho, items: const [
                  DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                  DropdownMenuItem(value: 'médio', child: Text('Médio')),
                  DropdownMenuItem(value: 'grande', child: Text('Grande')),
                ], onChanged: (v)=> setState(()=> tamanho=v! ), decoration: const InputDecoration(labelText: 'Tamanho'))),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(initialValue: sexo, items: const [
                  DropdownMenuItem(value: 'M', child: Text('Macho')),
                  DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                ], onChanged: (v)=> setState(()=> sexo=v! ), decoration: const InputDecoration(labelText: 'Sexo'))),
              ],
            ),

            const SizedBox(height: 8),
            Text('Idade (meses): $idade'),
            Slider(value: idade.toDouble(), min: 0, max: 120, divisions: 120, onChanged: (v)=> setState(()=> idade=v.round())),
            Text('Peso (kg): ${peso.toStringAsFixed(1)}'),
            Slider(value: peso, min: 0.5, max: 60, divisions: 119, onChanged: (v)=> setState(()=> peso=double.parse(v.toStringAsFixed(1)))),
            TextFormField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 3),
            const SizedBox(height: 12),
            Text('Personalidade', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_showAllPersonalities ? personalityOptions : personalityOptions.take(3).toList()).map((p) {
                final isSelected = _selectedPersonalities.contains(p);
                final c = colorForPersonality(p);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedPersonalities.remove(p);
                    } else {
                      _selectedPersonalities.add(p);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? c.withAlpha((0.2 * 255).round()) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? c : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(p, style: TextStyle(
                          color: isSelected ? c : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (personalityOptions.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _showAllPersonalities = !_showAllPersonalities),
                  child: Text(
                    _showAllPersonalities ? 'Ocultar' : '+${personalityOptions.length - 3} mais',
                    style: const TextStyle(
                      color: Color(0xFF824822),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Expectativa de vida (anos): $expectativaVidaAnos'),
                  Slider(value: expectativaVidaAnos.toDouble(), min: 0, max: 30, divisions: 30, onChanged: (v)=> setState(()=> expectativaVidaAnos = v.round())),
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
            Text('Cores', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_showAllColors ? kCommonColorTags : kCommonColorTags.take(6).toList()).map((tag) {
                final selected = _selectedColors.contains(tag);
                final c = colorForTag(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedColors.remove(tag);
                    } else {
                      _selectedColors.add(tag);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? c.withAlpha((0.2 * 255).round()) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? c : Colors.black12,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(tag, style: TextStyle(
                          color: selected ? c : Colors.black87,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (kCommonColorTags.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _showAllColors = !_showAllColors),
                  child: Text(
                    _showAllColors ? 'Ocultar' : '+${kCommonColorTags.length - 6} mais',
                    style: const TextStyle(
                      color: Color(0xFF824822),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
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
                // populate model from controllers/state
                a.nome = _nomeController.text.trim();
                a.descricao = _descricaoController.text.trim();
                a.personalidade = _selectedPersonalities.join(',');
                a.caracteristicas = _caracteristicasController.text.trim();
                a.tipo = tipo;
                a.sexo = sexo;
                a.idadeMeses = idade;
                a.pesoKg = peso;
                a.tamanho = tamanho;
                a.expectativaVidaAnos = expectativaVidaAnos;
                a.vacinado = vacinado;
                a.cor = _selectedColors.join(',');
                try {
                  await context.read<AppState>().updateAnimal(a);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado com sucesso')));
                  Navigator.of(context).pop();
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

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _caracteristicasController.dispose();
    super.dispose();
  }
}
