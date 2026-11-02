import 'package:adapta/dados/banco/seed.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('o banco nasce com todo o conteúdo do seed', () async {
    final banco = bancoDeTeste();
    final conteudo = await ConteudoRepositorio(banco).carregar();

    expect(conteudo.materias, hasLength(2));
    expect(conteudo.assuntosDaMateria(1).length, inInclusiveRange(12, 15));
    expect(conteudo.questoes, hasLength(questoesSeed.length));
    for (final a in conteudo.assuntosDaMateria(1)) {
      expect(
        conteudo.questoes.where((q) => q.idAssunto == a.id).length,
        3,
        reason: a.nome,
      );
    }
    await banco.fechar();
  });

  test('cada questão tem uma só alternativa certa e ids válidos', () {
    final ids = questoesSeed.map((q) => q.id).toSet();
    expect(ids.length, questoesSeed.length);
    for (final q in questoesSeed) {
      expect(q.alternativas.where((a) => a.correta), hasLength(1));
      expect(q.dificuldade, inInclusiveRange(1, 3));
    }
  });

  test('há 3 questões com imagem, e todas com descrição', () {
    final comImagem = questoesSeed.where((q) => q.imagemUrl != null).toList();
    expect(comImagem, hasLength(3));
    for (final q in comImagem) {
      expect(q.imagemUrl, startsWith('asset:assets/questoes/'));
      expect(q.imagemDescricao, isNotEmpty);
    }
  });

  test('as chaves estrangeiras estão ligadas', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    await expectLater(
      db.insert('Assunto', {
        'id': 999,
        'id_materia': 12345,
        'nome': 'x',
        'descricao': '',
      }),
      throwsA(anything),
    );
    await banco.fechar();
  });

  test('o seed não roda duas vezes no mesmo banco', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    final antes = await db.rawQuery('SELECT COUNT(*) AS n FROM Questao');
    await banco.db;
    final depois = await db.rawQuery('SELECT COUNT(*) AS n FROM Questao');
    expect(depois.first['n'], antes.first['n']);
    expect(
      (await SharedPreferences.getInstance()).getBool('seed_concluido'),
      isTrue,
    );
    await banco.fechar();
  });
}
