import 'package:flutter/material.dart';

/// Ícone e cor estáveis por matéria (por nome, com fallback por id).
({IconData icone, Color cor}) estiloMateria(String nome, int id) {
  final n = nome.toLowerCase();
  const regras = <(List<String>, IconData, Color)>[
    (['matem'], Icons.functions_rounded, Color(0xFF4F46E5)),
    (['hist'], Icons.account_balance_rounded, Color(0xFFD97706)),
    (['fís', 'fis'], Icons.bolt_rounded, Color(0xFF0EA5E9)),
    (['quím', 'quim'], Icons.science_rounded, Color(0xFF10B981)),
    (['bio'], Icons.eco_rounded, Color(0xFF22C55E)),
    (['geo'], Icons.public_rounded, Color(0xFF0D9488)),
    (['port', 'lit', 'redação'], Icons.menu_book_rounded, Color(0xFFDB2777)),
    (['ingl', 'espa'], Icons.translate_rounded, Color(0xFF7C3AED)),
    (['filo', 'socio'], Icons.psychology_rounded, Color(0xFF64748B)),
  ];
  for (final (chaves, icone, cor) in regras) {
    if (chaves.any(n.contains)) return (icone: icone, cor: cor);
  }
  const cores = [
    Color(0xFF4F46E5),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
  ];
  return (icone: Icons.auto_stories_rounded, cor: cores[id % cores.length]);
}
