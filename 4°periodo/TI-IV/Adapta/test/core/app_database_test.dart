import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_helpers.dart';

void main() {
  late Database db;

  setUp(() async => db = await bancoDeTeste());
  tearDown(() => db.close());

  test('cria as 9 tabelas da seção 9 da memória', () async {
    final linhas = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    final nomes = linhas.map((l) => l['name']).toSet();
    expect(
      nomes,
      containsAll([
        'Usuario',
        'Materia',
        'Assunto',
        'Grafo_Dependencia',
        'Questao',
        'Alternativa',
        'Historico_Estudo',
        'Nivel_Memoria',
        'Proficiencia',
      ]),
    );
  });

  test('seed insere admin, matérias, grafo e questões', () async {
    expect(await _conta(db, 'Usuario'), 1);
    expect(await _conta(db, 'Materia'), 2);
    expect(await _conta(db, 'Assunto'), 7);
    expect(await _conta(db, 'Grafo_Dependencia'), 6);
    expect(await _conta(db, 'Questao'), 7);
  });

  test('foreign keys ligadas: apagar matéria apaga assuntos', () async {
    await db.delete('Materia', where: 'nome = ?', whereArgs: ['História']);
    expect(await _conta(db, 'Assunto'), 5);
  });

  test('aresta duplicada é rejeitada pela chave composta', () async {
    final a = await db.query('Grafo_Dependencia', limit: 1);
    await expectLater(
      () => db.insert('Grafo_Dependencia', a.first),
      throwsA(isA<DatabaseException>()),
    );
  });
}

Future<int> _conta(Database db, String tabela) async =>
    Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tabela'))!;
