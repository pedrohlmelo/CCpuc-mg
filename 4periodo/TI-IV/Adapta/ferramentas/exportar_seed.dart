// Exporta as questões de assets/conteudo/ para o treino da IA.
//   dart run ferramentas/exportar_seed.dart
// Saída: ia/seed.json
import 'dart:convert';
import 'dart:io';

Map<String, dynamic> _ler(String arquivo) =>
    jsonDecode(File('assets/conteudo/$arquivo').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final assuntos = <int>[];
  final questoes = <Map<String, dynamic>>[];
  for (final m in _ler('indice.json')['materias'] as List) {
    final materia = _ler(m['arquivo'] as String);
    for (final a in materia['assuntos'] as List) {
      assuntos.add(a['id'] as int);
    }
    for (final q in materia['questoes'] as List) {
      questoes.add({
        'id': q['id'],
        'id_assunto': q['assunto'],
        'dificuldade': q['dificuldade'],
      });
    }
  }
  assuntos.sort();
  questoes.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

  final saida = {'assuntos': assuntos, 'questoes': questoes};
  File('ia/seed.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(saida));
  stdout.writeln('ia/seed.json: ${questoes.length} questões');
}
