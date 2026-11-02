// Exporta as questões do seed para o treino da IA.
//   dart run ferramentas/exportar_seed.dart
// Saída: ia/seed.json
import 'dart:convert';
import 'dart:io';

import 'package:adapta/dados/banco/seed.dart';

void main() {
  final saida = {
    'assuntos': [for (final a in assuntosSeed) a.id],
    'questoes': [
      for (final q in questoesSeed)
        {'id': q.id, 'id_assunto': q.idAssunto, 'dificuldade': q.dificuldade},
    ],
  };
  File('ia/seed.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(saida));
  stdout.writeln('ia/seed.json: ${questoesSeed.length} questões');
}
