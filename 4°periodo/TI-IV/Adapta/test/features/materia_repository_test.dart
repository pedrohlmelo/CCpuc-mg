import 'package:adapta/features/materias/data/materia_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_helpers.dart';

void main() {
  late Database db;
  late MateriaRepository repo;

  setUp(() async {
    db = await bancoDeTeste();
    repo = MateriaRepository(db);
  });
  tearDown(() => db.close());

  test('lista matérias do seed em ordem alfabética (RF02)', () async {
    final nomes = (await repo.listar()).map((m) => m.nome).toList();
    expect(nomes, ['História', 'Matemática']);
  });

  test('cria matéria e assunto', () async {
    final fisica = await repo.criar('Física');
    await repo.criarAssunto(idMateria: fisica.id, nome: 'Cinemática');
    final assuntos = await repo.listarAssuntos(idMateria: fisica.id);
    expect(assuntos.single.nome, 'Cinemática');
  });

  test('listarAssuntos sem filtro devolve todos', () async {
    expect((await repo.listarAssuntos()).length, 7);
  });
}
