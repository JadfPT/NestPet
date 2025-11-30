import 'package:flutter/material.dart';

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
  final TextEditingController corController = TextEditingController();
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
    corController.text = widget.initialCor ?? '';
    caracteristicasController.text = widget.initialCaracteristicas ?? '';
    final min = widget.initialPesoMin ?? 0.0;
    final max = widget.initialPesoMax ?? 40.0;
    peso = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            TextField(
              controller: corController,
              decoration: const InputDecoration(labelText: 'Cor'),
              onChanged: (_) => setState(() {}),
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
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop({
                'tipo': tipo,
                'tamanho': tamanho,
                'idade': idade.round(),
                'sexo': sexo,
                'vacinado': vacinado,
                'cor': corController.text.trim().isEmpty ? null : corController.text.trim(),
                'pesoMin': peso.start.round(),
                'pesoMax': peso.end.round(),
                'caracteristicas': caracteristicasController.text.trim().isEmpty ? null : caracteristicasController.text.trim(),
              }),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    corController.dispose();
    caracteristicasController.dispose();
    super.dispose();
  }
}
