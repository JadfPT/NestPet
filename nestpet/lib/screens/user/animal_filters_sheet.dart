import 'package:flutter/material.dart';
import '../../utils/color_tags.dart';

class AnimalFiltersSheet extends StatefulWidget {
  final String? initialTipo;
  final String? initialTamanho;
  final int? initialIdadeMax;
  final String? initialSexo;
  final bool? initialVacinado;
  final String? initialCor;
  final double? initialPesoMin;
  final double? initialPesoMax;
  

  const AnimalFiltersSheet({
    super.key,
    this.initialTipo,
    this.initialTamanho,
    this.initialIdadeMax,
    this.initialSexo,
    this.initialVacinado,
    this.initialCor,
    this.initialPesoMin,
    this.initialPesoMax,
  });

  @override
  State<AnimalFiltersSheet> createState() => _AnimalFiltersSheetState();
}

class _AnimalFiltersSheetState extends State<AnimalFiltersSheet> {
  String? tipo;
  String? tamanho;
  double idade = 60;
  String? sexo;
  bool? vacinado;
  // selected color tags for filters (stored as CSV when applying)
  final Set<String> _selectedColors = {};
  bool _showColorChips = false;
  
  RangeValues peso = const RangeValues(0, 100);

  @override
  void initState() {
    super.initState();
    tipo = widget.initialTipo;
    tamanho = widget.initialTamanho;
    idade = (widget.initialIdadeMax ?? 60).toDouble();
    sexo = widget.initialSexo;
    vacinado = widget.initialVacinado;
    // parse initialCor CSV into selected set
    final initialCor = widget.initialCor ?? '';
    _selectedColors.addAll(initialCor.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    
    final min = widget.initialPesoMin ?? 0.0;
    final max = widget.initialPesoMax ?? 40.0;
    peso = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final String selectedSummary = _selectedColors.isEmpty
        ? 'Nenhuma selecionada'
        : (_selectedColors.length > 3
            ? 'Selecionadas: ${_selectedColors.take(3).join(', ')} +${_selectedColors.length - 3}'
            : 'Selecionadas: ${_selectedColors.take(3).join(', ')}');

    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border.all(color: primary.withAlpha((0.18*255).round()), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.06*255).round()), blurRadius: 10)],
            ),
            child: Column(
              children: [
                // drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Center(
                    child: Container(width: 36, height: 4, decoration: BoxDecoration(color: primary.withAlpha((0.22*255).round()), borderRadius: BorderRadius.circular(4))),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Limpar filtros',
                              onPressed: () {
                                // Clear local state and immediately return empty filters
                                tipo = null;
                                tamanho = null;
                                idade = 60;
                                sexo = null;
                                vacinado = null;
                                _selectedColors.clear();
                                _showColorChips = false;
                                peso = const RangeValues(0, 40);
                                Navigator.of(context).pop({
                                  'tipo': null,
                                  'tamanho': null,
                                  'idade': null,
                                  'sexo': null,
                                  'vacinado': null,
                                  'cor': null,
                                  'pesoMin': null,
                                  'pesoMax': null,
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: tipo,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const [
                            DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                            DropdownMenuItem(value: 'Gato', child: Text('Gato')),
                            DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                          ],
                          onChanged: (v) => setState(() => tipo = v),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: tamanho,
                          decoration: const InputDecoration(labelText: 'Tamanho'),
                          items: const [
                            DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                            DropdownMenuItem(value: 'médio', child: Text('Médio')),
                            DropdownMenuItem(value: 'grande', child: Text('Grande')),
                          ],
                          onChanged: (v) => setState(() => tamanho = v),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: sexo ?? '',
                          decoration: const InputDecoration(labelText: 'Sexo'),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Indiferente')),
                            DropdownMenuItem(value: 'M', child: Text('Macho')),
                            DropdownMenuItem(value: 'F', child: Text('Fêmea')),
                          ],
                          onChanged: (v) => setState(() => sexo = (v == '' ? null : v)),
                        ),
                        SwitchListTile(
                          title: const Text('Vacinado'),
                          value: vacinado ?? false,
                          onChanged: (v) => setState(() => vacinado = v ? true : null),
                        ),
                        Row(
                          children: [
                            const Expanded(child: Text('Cor')),
                            IconButton(icon: Icon(_showColorChips ? Icons.expand_less : Icons.expand_more), onPressed: () => setState(() => _showColorChips = !_showColorChips)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (_showColorChips)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: kCommonColorTags.map((tag) {
                              final sel = _selectedColors.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: sel,
                                selectedColor: primary.withAlpha((0.14*255).round()),
                                labelStyle: TextStyle(color: sel ? primary : null),
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
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(selectedSummary)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(children: [
                            const Text('Idade máx. (meses)'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(activeTrackColor: primary, thumbColor: primary, overlayColor: primary.withAlpha((0.12*255).round())),
                                child: Slider(value: idade, min: 2, max: 120, divisions: 59, label: idade.round().toString(), onChanged: (v) => setState(() => idade = v)),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Peso (kg)'),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(activeTrackColor: primary, thumbColor: primary, overlayColor: primary.withAlpha((0.12*255).round())),
                            child: RangeSlider(values: peso, min: 0, max: 100, divisions: 100, labels: RangeLabels(peso.start.round().toString(), peso.end.round().toString()), onChanged: (v) => setState(() => peso = v)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        // Características field removed per design decision.
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop({
                              'tipo': tipo,
                              'tamanho': tamanho,
                              // se o utilizador não mexeu, devolve null para não filtrar
                              'idade': (idade == 60) ? null : idade.round(),
                              'sexo': sexo,
                              'vacinado': vacinado,
                              'cor': _selectedColors.isEmpty ? null : _selectedColors.join(','),
                              'pesoMin': (peso.start == 0) ? null : peso.start,
                              'pesoMax': (peso.end == 100) ? null : peso.end,
                            }),
                            child: const Text('Aplicar'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // caracteristicasController.dispose(); // Removed as the controller is no longer needed
    super.dispose();
  }
}
