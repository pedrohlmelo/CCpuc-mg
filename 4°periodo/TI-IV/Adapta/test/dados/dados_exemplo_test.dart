import 'package:adapta/dados/dados_exemplo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os dados de exemplo são escritos à mão, então vale checar se estão
/// coerentes: as telas contam com isso para desenhar sem erro.
void main() {
  test('ids de matéria, assunto e questão são únicos', () {
    expect(
      materiasExemplo.map((m) => m.id).toSet().length,
      materiasExemplo.length,
    );
    expect(
      assuntosExemplo.map((a) => a.id).toSet().length,
      assuntosExemplo.length,
    );
    expect(
      questoesExemplo.map((q) => q.id).toSet().length,
      questoesExemplo.length,
    );
  });

  test('cada questão tem exatamente uma alternativa correta', () {
    for (final q in questoesExemplo) {
      expect(
        q.alternativas.where((a) => a.correta).length,
        1,
        reason: 'questão ${q.id}',
      );
    }
  });

  test('toda questão aponta para um assunto existente', () {
    for (final q in questoesExemplo) {
      expect(assuntoPorId(q.idAssunto), isNotNull, reason: 'questão ${q.id}');
    }
  });

  test('todo assunto aponta para uma matéria existente', () {
    for (final a in assuntosExemplo) {
      expect(materiaPorId(a.idMateria), isNotNull, reason: 'assunto ${a.id}');
    }
  });

  test('as arestas do grafo ligam assuntos existentes', () {
    for (final d in dependenciasExemplo) {
      expect(assuntoPorId(d.prerequisito), isNotNull);
      expect(assuntoPorId(d.dependente), isNotNull);
      expect(d.prerequisito, isNot(d.dependente));
    }
  });

  test('o histórico de exemplo só cita questões existentes', () {
    for (final r in historicoExemplo()) {
      expect(questaoPorId(r.idQuestao), isNotNull);
    }
  });

  test('o filtro por matéria devolve só questões daquela matéria', () {
    final historia = questoesDaMateria(2);
    expect(historia, isNotEmpty);
    for (final q in historia) {
      expect(assuntoPorId(q.idAssunto)!.idMateria, 2);
    }
    expect(questoesDaMateria(null).length, questoesExemplo.length);
  });
}
