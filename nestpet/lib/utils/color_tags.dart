import 'package:flutter/material.dart';

/// Lista de cores comuns para animais (rótulo -> cor real).
const List<String> kCommonColorTags = [
  'Preto',
  'Branco',
  'Castanho',
  'Tigrado',
  'Malhado',
  'Cinza',
  'Dourado',
  'Caramelo',
  'Bege',
];

final Map<String, Color> kColorTagMap = {
  'Preto': Colors.black,
  'Branco': Colors.white,
  'Castanho': const Color(0xFF6B3E26),
  'Tigrado': const Color(0xFFB66A00),
  'Malhado': const Color(0xFF8A6B4F),
  'Cinza': Colors.grey,
  'Dourado': const Color(0xFFFFC857),
  'Caramelo': const Color(0xFFD2A679),
  'Bege': const Color(0xFFF5E6CC),
};

Color colorForTag(String tag) {
  return kColorTagMap[tag] ?? Colors.grey.shade400;
}
