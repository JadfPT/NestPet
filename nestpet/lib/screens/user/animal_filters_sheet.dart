import 'package:flutter/material.dart';

class AnimalFiltersSheet extends StatefulWidget {
  final String? initialTipo;
  final String? initialTamanho;
  final int? initialIdadeMax;
  const AnimalFiltersSheet({super.key, this.initialTipo, this.initialTamanho, this.initialIdadeMax});

  @override
  State<AnimalFiltersSheet> createState() => _AnimalFiltersSheetState();
}

class _AnimalFiltersSheetState extends State<AnimalFiltersSheet> {
  String? tipo;
  String? tamanho;
  double idade = 60;

  @override
  void initState() {
    super.initState();
    tipo = widget.initialTipo;
    tamanho = widget.initialTamanho;
    idade = (widget.initialIdadeMax ?? 60).toDouble();
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
              value: tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'Cão', child: Text('Cão')),
                DropdownMenuItem(value: 'Gato', child: Text('Gato')),
              ],
              onChanged: (v) => setState(() => tipo = v),
            ),
            DropdownButtonFormField<String>(
              value: tamanho,
              decoration: const InputDecoration(labelText: 'Tamanho'),
              items: const [
                DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                DropdownMenuItem(value: 'médio', child: Text('Médio')),
                DropdownMenuItem(value: 'grande', child: Text('Grande')),
              ],
              onChanged: (v) => setState(() => tamanho = v),
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
            FilledButton(
              onPressed: () => Navigator.of(context).pop({'tipo': tipo, 'tamanho': tamanho, 'idade': idade.round()}),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}
