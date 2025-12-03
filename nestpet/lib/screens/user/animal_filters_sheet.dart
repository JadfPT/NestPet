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
  final String? initialCaracteristicas;

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
    this.initialCaracteristicas,
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
  final TextEditingController caracteristicasController = TextEditingController();
  RangeValues peso = const RangeValues(0, 40);

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
    caracteristicasController.text = widget.initialCaracteristicas ?? '';
    final min = widget.initialPesoMin ?? 0.0;
    final max = widget.initialPesoMax ?? 40.0;
    peso = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final String _selectedSummary = _selectedColors.isEmpty
        ? 'Nenhuma selecionada'
        : (_selectedColors.length > 3
            ? 'Selecionadas: ${_selectedColors.take(3).join(', ')} +${_selectedColors.length - 3}'
            : 'Selecionadas: ${_selectedColors.take(3).join(', ')}');

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        // Reduce horizontal padding so the sheet appears wider and
        // remove bottom padding so it sits flush to the bottom.
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: SizedBox(height: MediaQuery.of(context).size.height * 0.60, child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2E8D7),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                border: Border.fromBorderSide(BorderSide(color: Color(0xFF824822), width: 3)),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Limpar filtros',
                        onPressed: () => setState(() {
                          tipo = null;
                          tamanho = null;
                          idade = 60;
                          sexo = null;
                          vacinado = null;
                          _selectedColors.clear();
                          _showColorChips = false;
                          caracteristicasController.text = '';
                          peso = const RangeValues(0, 40);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                      DropdownMenuItem(value: 'Gato', child: Text('Gato')),
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
                    value: sexo ?? '',
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
                    onChanged: (v) => setState(() => vacinado = v),
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Cor')),
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
                        final sel = _selectedColors.contains(tag);
                        return FilterChip(label: Text(tag), selected: sel, onSelected: (v) => setState(() { if (v) _selectedColors.add(tag); else _selectedColors.remove(tag); }));
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(_selectedSummary),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Idade máx. (meses)'),
                      Expanded(
                        child: Slider(
                          value: idade,
                          min: 2, max: 120, divisions: 59,
                          label: idade.round().toString(),
                          onChanged: (v) => setState(() => idade = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peso (kg)'),
                      RangeSlider(
                        values: peso,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        labels: RangeLabels(peso.start.round().toString(), peso.end.round().toString()),
                        onChanged: (v) => setState(() => peso = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: caracteristicasController,
                    decoration: const InputDecoration(labelText: 'Características '),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop({
                      'tipo': tipo,
                      'tamanho': tamanho,
                      'idade': idade.round(),
                      'sexo': sexo,
                      'vacinado': vacinado,
                      'cor': _selectedColors.isEmpty ? null : _selectedColors.join(','),
                      'pesoMin': peso.start.round(),
                      'pesoMax': peso.end.round(),
                      'caracteristicas': caracteristicasController.text.trim().isEmpty ? null : caracteristicasController.text.trim(),
                    }),
                    child: const Text('Aplicar'),
                  ),
                      ], // Column children
                    ), // Column
                  ), // SingleChildScrollView
                  // separator line at the bottom of the sheet to visually separate
                  // it from the bottom bar / FAB
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFF824822),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
                      ),
                    ),
                  ),
                ],
              ), // Stack
          ), // Container
        ), // SizedBox
      ), // Padding
    ); // SafeArea
  }

  @override
  void dispose() {
    caracteristicasController.dispose();
    super.dispose();
  }
}
