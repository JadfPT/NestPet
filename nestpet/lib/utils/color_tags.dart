import 'package:flutter/material.dart';

/// Lista de cores/tintas comuns para animais (rótulo -> cor real).
/// Expandida para cobrir um espectro maior de tonalidades.
const List<String> kCommonColorTags = [
  'Preto',
  'Branco',
  'Cinza Escuro',
  'Cinza',
  'Cinza Claro',
  'Castanho Escuro',
  'Castanho',
  'Castanho Claro',
  'Chocolate',
  'Caramelo',
  'Dourado',
  'Bege',
  'Creme',
  'Ruivo',
  'Tigrado',
  'Malhado',
  'Malhado Preto',
  'Malhado Branco',
  'Laranja',
  'Amarelo',
];

final Map<String, Color> kColorTagMap = {
  'Preto': Colors.black,
  'Branco': Colors.white,
  'Cinza Escuro': const Color(0xFF4A4A4A),
  'Cinza': Colors.grey,
  'Cinza Claro': const Color(0xFFBFC5CA),
  'Castanho Escuro': const Color(0xFF5A391F),
  'Castanho': const Color(0xFF6B3E26),
  'Castanho Claro': const Color(0xFF8C5E3C),
  'Chocolate': const Color(0xFF3E2723),
  'Caramelo': const Color(0xFFD2A679),
  'Dourado': const Color(0xFFFFC857),
  'Bege': const Color(0xFFF5E6CC),
  'Creme': const Color(0xFFFFF3E0),
  'Ruivo': const Color(0xFFB04A2E),
  'Tigrado': const Color(0xFFB66A00),
  'Malhado': const Color(0xFF8A6B4F),
  'Malhado Preto': const Color(0xFF2F2F2F),
  'Malhado Branco': const Color(0xFFF7F7F7),
  'Laranja': const Color(0xFFFF8A00),
  'Amarelo': const Color(0xFFFFE082),
};

Color colorForTag(String tag) {
  return kColorTagMap[tag] ?? Colors.grey.shade400;
}
