import 'package:adapta/features/questoes/data/historico_repository.dart';
import 'package:adapta/features/questoes/data/questao_repository.dart';
import 'package:adapta/pilares/recomendacao/recomendador.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_helpers.dart';

void main() {
  late Database db;
  late QuestaoRepository questoes;
  late HistoricoRepository historico;

  setUp(() async {
    db = await bancoDeTeste();
    questoes = QuestaoRepository(db);
    historico = HistoricoRepository(db);
  });
  tearDown(() => db.close());

  test('carrega questão com alternativas e gabarito (RF04)', () async {
    final q = await questoes.buscarPorId(1);
    expect(q, isNotNull);
    expect(q!.alternativas.length, 4);
    expect(q.gabarito.letra, 'B');
  });

  test('filtra por matéria', () async {
    final materias = await db.query(
      'Materia',
      where: 'nome = ?',
      whereArgs: ['História'],
    );
    final id = materias.first['id'] as int;
    expect((await questoes.listar(idMateria: id)).length, 2);
  });

  test('registra histórico e recomendador pula respondidas', () async {
    const aluno = 1; // admin do seed serve como usuário nos testes
    final rec = RecomendadorSequencial(questoes, historico);

    final primeira = await rec.proximaQuestao(idUsuario: aluno);
    expect(primeira, isNotNull);

    await historico.registrar(
      idUsuario: aluno,
      idQuestao: primeira!.id,
      acertou: true,
    );

    final segunda = await rec.proximaQuestao(idUsuario: aluno);
    expect(segunda!.id, isNot(primeira.id));
    expect((await historico.listarDoUsuario(aluno)).single.acertou, isTrue);
  });

  test('criar questão exige uma alternativa correta', () async {
    final q = await questoes.criar(
      idAssunto: 1,
      enunciado: '2 + 2?',
      alternativas: [
        (letra: 'A', texto: '3', correta: false),
        (letra: 'B', texto: '4', correta: true),
      ],
    );
    expect(q.gabarito.texto, '4');
  });
}
