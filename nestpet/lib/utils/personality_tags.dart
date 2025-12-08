// Propósito geral: Definir opções de traços de personalidade e uma função
// que mapeia cada traço para uma cor consistente na UI.
// Observações:
// - As opções são usadas para tags/etiquetas em ecrãs; podem ser traduzidas/alteradas conforme necessidade.
// - O mapeamento de cores é simples e pode ser ajustado para melhor contraste/tema.

import 'package:flutter/material.dart';

// Lista de opções de personalidade disponíveis para seleção/visualização.
const List<String> personalityOptions = [
  'Amigável',
  'Tímido',
  'Agressivo',
  'Brincalhão',
  'Calmo',
  'Energético',
  'Inteligente',
  'Carinhoso',
  'Independente',
  'Sociável',
  'Curioso',
  'Preguiçoso',
  'Protetor',
  'Dócil',
  'Nervoso',
];

// Devolve uma cor representativa para um traço de personalidade.
// Normaliza o texto para comparação e usa um mapa predefinido.
Color colorForPersonality(String personality) {
  final p = personality.toLowerCase().trim();
  
  // Mapa entre traços (lowercase) e cores Material.
  final colors = {
    'amigável': Colors.blue,
    'tímido': Colors.purple,
    'agressivo': Colors.red,
    'brincalhão': Colors.orange,
    'calmo': Colors.green,
    'energético': Colors.amber,
    'inteligente': Colors.indigo,
    'carinhoso': Colors.pink,
    'independente': Colors.grey,
    'sociável': Colors.cyan,
    'curioso': Colors.teal,
    'preguiçoso': Colors.brown,
    'protetor': Colors.deepOrange,
    'dócil': Colors.lightBlue,
    'nervoso': Colors.yellow,
  };
  
  // Cor por defeito caso o traço não esteja no mapa.
  return colors[p] ?? Colors.blueGrey;
}
