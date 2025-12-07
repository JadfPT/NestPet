import 'package:flutter/material.dart';

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

Color colorForPersonality(String personality) {
  final p = personality.toLowerCase().trim();
  
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
  
  return colors[p] ?? Colors.blueGrey;
}
