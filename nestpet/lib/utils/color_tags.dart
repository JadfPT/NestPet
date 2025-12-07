import 'package:flutter/material.dart';

/// Lista de cores/tintas comuns para animais (rótulo -> cor real).
/// Expandida para cobrir um espectro maior de tonalidades.
const List<String> kCommonColorTags = [
  'Preto',
  'Branco',
  'Cinza Escuro',
  'Cinza',
  'Castanho Escuro',
  'Castanho',
  'Castanho Claro',
  'Caramelo',
  'Dourado',
  'Verde',
  'Verde Lima',
  'Verde Musgo',
  'Turquesa',
  'Azul Céu',
  'Azul Marinho',
  'Vermelho',
  'Rosa',
  'Roxo',
  'Ruivo',
  'Tigrado',
  'Amarelo',
];

final Map<String, Color> kColorTagMap = {
  'Preto': Colors.black,
  'Branco': Colors.white,
  'Cinza Escuro': const Color(0xFF4A4A4A),
  'Cinza': Colors.grey,
  'Castanho Escuro': const Color(0xFF5A391F),
  'Castanho': const Color(0xFF6B3E26),
  'Castanho Claro': const Color(0xFF8C5E3C),
  'Caramelo': const Color(0xFFD2A679),
  'Dourado': const Color(0xFFFFC857),
  'Verde': const Color(0xFF4CAF50),
  'Verde Lima': const Color(0xFF9CCC65),
  'Verde Musgo': const Color(0xFF556B2F),
  'Turquesa': const Color(0xFF26C6DA),
  'Azul Céu': const Color(0xFF81D4FA),
  'Azul Marinho': const Color(0xFF0D47A1),
  'Vermelho': const Color(0xFFE53935),
  'Rosa': const Color(0xFFF48FB1),
  'Roxo': const Color(0xFF7E57C2),
  'Ruivo': const Color(0xFFB04A2E),
  'Tigrado': const Color(0xFFB66A00),
  'Amarelo': const Color(0xFFFFE082),
};

Color colorForTag(String tag) {
  return kColorTagMap[tag] ?? Colors.grey.shade400;
}
