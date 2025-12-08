// Propósito geral: Folha modal de filtros para a lista de animais, permitindo
// selecionar tipo, tamanho, idade máxima, sexo, estado de vacinação, cores e
// intervalo de peso.
// Observações:
// - Recebe valores iniciais para pré-preencher o formulário.
// - Ao aplicar/limpar, devolve um mapa com os filtros via Navigator.pop.
// - Mantém estado interno (seleções) e apresenta chips de cor opcionais.

import 'package:flutter/material.dart';
import '../../utils/color_tags.dart';

// Folha de filtros com parâmetros iniciais opcionais.
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
  // Campos de filtro atuais.
  String? tipo;
  String? tamanho;
  double idade = 60;
  String? sexo;
  bool? vacinado;
  // Seleção de cores (conjunto para fácil toggle) e controlo de visibilidade dos chips.
  final Set<String> _selectedColors = {};
  bool _showColorChips = false;
  
  // Intervalo de peso em kg.
  RangeValues peso = const RangeValues(0, 100);

  @override
  void initState() {
    super.initState();
    // Carrega valores iniciais para o estado local.
    tipo = widget.initialTipo;
    tamanho = widget.initialTamanho;
    idade = (widget.initialIdadeMax ?? 60).toDouble();
    sexo = widget.initialSexo;
    vacinado = widget.initialVacinado;
    final initialCor = widget.initialCor ?? '';
    // Divide lista de cores (separadas por vírgulas) e adiciona ao conjunto.
    _selectedColors.addAll(initialCor.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    
    final min = widget.initialPesoMin ?? 0.0;
    final max = widget.initialPesoMax ?? 40.0;
    peso = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    // Resumo textual das cores selecionadas (mostra até 3).
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
          // Altura proporcional ao ecrã.
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
                // Indicador de arrastar no topo.
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
                        // Cabeçalho com título e ação para limpar filtros.
                        Row(
                          children: [
                            const Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Limpar filtros',
                              onPressed: () {
                                // Repõe valores por defeito e fecha devolvendo nulls.
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
                        // Tipo: Cão/Gato/Outro.
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
                        // Tamanho: pequeno/médio/grande.
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
                        // Sexo: indiferente/macho/fêmea.
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
                        // Vacinado: tri-state (true/null=>indiferente via toggle simples).
                        SwitchListTile(
                          title: const Text('Vacinado'),
                          value: vacinado ?? false,
                          onChanged: (v) => setState(() => vacinado = v ? true : null),
                        ),
                        // Secção de cor: chips expansíveis.
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
                          // Quando recolhido, mostra sumário breve.
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Text(selectedSummary)),
                        const SizedBox(height: 8),
                        // Idade máxima em meses (2..120) com slider.
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
                        // Intervalo de peso (0..100 kg) com RangeSlider.
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Peso (kg)'),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(activeTrackColor: primary, thumbColor: primary, overlayColor: primary.withAlpha((0.12*255).round())),
                            child: RangeSlider(values: peso, min: 0, max: 100, divisions: 100, labels: RangeLabels(peso.start.round().toString(), peso.end.round().toString()), onChanged: (v) => setState(() => peso = v)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        const SizedBox(height: 12),
                        // Botão aplicar: devolve mapa de filtros, omitindo valores por defeito.
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop({
                              'tipo': tipo,
                              'tamanho': tamanho,
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
    // Sem controladores adicionais a libertar.
    super.dispose();
  }
}
