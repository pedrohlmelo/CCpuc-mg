import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/banco/pacote_conteudo.dart';
import 'package:adapta/dados/banco/seed.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/repositorios/admin_conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/grafo_repositorio.dart';
import 'package:adapta/dados/repositorios/historico_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

const _admin = Usuario(id: 1, nome: 'Admin', tipo: TipoUsuario.admin);

Questao questaoNova({
  int id = 0,
  int idAssunto = 1,
  String enunciado = 'Quanto é 2 + 2?',
  String correta = 'C',
  int dificuldade = 1,
}) => Questao(
  id: id,
  idAssunto: idAssunto,
  enunciado: enunciado,
  explicacao: 'Soma simples.',
  dificuldade: dificuldade,
  alternativas: [
    for (final (i, letra) in letrasAlternativas.indexed)
      Alternativa(letra: letra, texto: '${i + 2}', correta: letra == correta),
  ],
);

void main() {
  late BancoLocal banco;
  late AdminConteudoRepositorio admin;
  var mudancas = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    mudancas = 0;
    admin = AdminConteudoRepositorio(
      banco,
      usuarioAtual: () => _admin,
      aoMudar: () => mudancas++,
    );
  });

  tearDown(() => banco.fechar());

  Future<Map<String, Object?>> linha(String tabela, int id) async {
    final db = await banco.db;
    return (await db.query(tabela, where: 'id = ?', whereArgs: [id])).single;
  }

  Future<Conteudo> conteudo() => ConteudoRepositorio(banco).carregar();

  test('banco novo nasce na versão 4 com as colunas do painel', () async {
    final db = await banco.db;
    expect((await db.rawQuery('PRAGMA user_version')).first.values.first, 4);
    expect(BancoLocal.versao, 4);
    final materia = await linha('Materia', 1);
    expect(materia['ativo'], 1);
    expect(materia['sincronizado'], 1);
    final tabelas = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
    );
    expect(tabelas.first['n'], 9);
  });

  test('aluno não grava nada', () async {
    final aluno = AdminConteudoRepositorio(
      banco,
      usuarioAtual: () => const Usuario(nome: 'Ana'),
    );
    expect(
      () => aluno.criarMateria('Nova matéria X', 'matematica'),
      throwsA(isA<ErroAdmin>()),
    );
  });

  test('criar e editar matéria grava e marca pendente', () async {
    final id = await admin.criarMateria('Nova matéria X', 'natureza');
    var m = await linha('Materia', id);
    expect(m['nome'], 'Nova matéria X');
    expect(m['sincronizado'], 0);
    expect(m['atualizado_em'], isNotNull);
    expect(mudancas, 1);

    await admin.editarMateria(id, 'Nova 2', 'humanas');
    m = await linha('Materia', id);
    expect(m['nome'], 'Nova 2');
    expect(m['area'], 'humanas');
    expect(await admin.contarPendentes(), 1);

    expect(
      () => admin.criarMateria('matemática', 'matematica'),
      throwsA(isA<ErroAdmin>()),
    );
    expect(
      () => admin.criarMateria('  ', 'matematica'),
      throwsA(isA<ErroAdmin>()),
    );
    expect(() => admin.criarMateria('X', 'outra'), throwsA(isA<ErroAdmin>()));
  });

  test('assunto ganha id da matéria e marca a matéria', () async {
    final materia = await admin.criarMateria('Nova matéria X', 'natureza');
    final a1 = await admin.criarAssunto(materia, 'Um', 'desc');
    final a2 = await admin.criarAssunto(materia, 'Dois', '');
    expect(a1, materia * 100 + 1);
    expect(a2, materia * 100 + 2);
    expect(
      () => admin.criarAssunto(materia, 'um', ''),
      throwsA(isA<ErroAdmin>()),
    );

    await admin.editarAssunto(a1, 'Um editado', 'nova');
    expect((await linha('Assunto', a1))['nome'], 'Um editado');

    // Matéria 1 (Matemática) já tem assuntos 101..106: o próximo livre é 107.
    expect(await admin.criarAssunto(1, 'Matrizes', ''), 107);
    expect((await linha('Materia', 1))['sincronizado'], 0);
  });

  test('excluir assunto desativa as questões e tira as arestas', () async {
    // Assunto 701 (Estequiometria) tem arestas com Matemática e Química.
    final antes = await admin.impactoAssunto(701);
    expect(antes.questoes, greaterThan(0));

    await admin.excluirAssunto(701);

    final db = await banco.db;
    expect((await linha('Assunto', 701))['ativo'], 0);
    final ativas = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Questao WHERE id_assunto = 701 AND ativo = 1',
    );
    expect(ativas.first['n'], 0);
    final arestas = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Grafo_Dependencia '
      'WHERE id_prerequisito = 701 OR id_dependente = 701',
    );
    expect(arestas.first['n'], 0);
    // Química e Matemática (16 → 701) ficam pendentes.
    expect((await linha('Materia', 7))['sincronizado'], 0);
    expect((await linha('Materia', 1))['sincronizado'], 0);

    final c = await conteudo();
    expect(c.assuntos.any((a) => a.id == 701), isFalse);
    expect(c.assuntoPorId(701)?.nome, 'Estequiometria');
    expect(c.questoes.any((q) => q.idAssunto == 701), isFalse);

    await admin.reativarAssunto(701);
    expect((await linha('Assunto', 701))['ativo'], 1);
  });

  test(
    'excluir matéria desativa assuntos e questões e some do aluno',
    () async {
      final impacto = await admin.impactoMateria(7);
      expect(impacto.assuntos, 6);
      expect(impacto.questoes, greaterThan(0));

      await admin.excluirMateria(7);

      final c = await conteudo();
      expect(c.materias.any((m) => m.id == 7), isFalse);
      expect(c.todasMaterias.firstWhere((m) => m.id == 7).ativo, isFalse);
      expect(c.assuntos.any((a) => a.idMateria == 7), isFalse);
      expect(c.questoesDaMateria(7), isEmpty);
      final grafo = await GrafoRepositorio(banco).listar();
      final daQuimica = c.todosAssuntos
          .where((a) => a.idMateria == 7)
          .map((a) => a.id)
          .toSet();
      expect(
        grafo.any(
          (d) =>
              daQuimica.contains(d.prerequisito) ||
              daQuimica.contains(d.dependente),
        ),
        isFalse,
      );

      await admin.reativarMateria(7);
      expect((await conteudo()).materias.any((m) => m.id == 7), isTrue);
    },
  );

  test('aresta: ciclo entre matérias é recusado com o caminho', () async {
    // Já existe 16 (Razão e proporção) → 701 (Estequiometria).
    await expectLater(
      admin.criarAresta(const Dependencia(prerequisito: 701, dependente: 16)),
      throwsA(
        isA<ErroAdmin>().having((e) => e.caminho, 'caminho', [16, 701, 16]),
      ),
    );
    await expectLater(
      admin.criarAresta(const Dependencia(prerequisito: 16, dependente: 701)),
      throwsA(isA<ErroAdmin>()),
    );
    await expectLater(
      admin.criarAresta(
        const Dependencia(prerequisito: 1, dependente: 701, peso: 1.5),
      ),
      throwsA(isA<ErroAdmin>()),
    );
    expect(await admin.contarPendentes(), 0);

    await admin.criarAresta(
      const Dependencia(prerequisito: 1, dependente: 701, peso: 0.3),
    );
    expect((await linha('Materia', 1))['sincronizado'], 0);
    expect((await linha('Materia', 7))['sincronizado'], 0);

    await admin.editarPeso(1, 701, 0.8);
    var arestas = await GrafoRepositorio(banco).listar();
    expect(
      arestas
          .firstWhere((d) => d.prerequisito == 1 && d.dependente == 701)
          .peso,
      0.8,
    );
    await admin.removerAresta(1, 701);
    arestas = await GrafoRepositorio(banco).listar();
    expect(
      arestas.any((d) => d.prerequisito == 1 && d.dependente == 701),
      isFalse,
    );
  });

  test('questão: cria no intervalo do painel e marca pendente', () async {
    final id = await admin.salvarQuestao(questaoNova());
    expect(id, primeiroIdQuestaoAdmin);
    expect(
      await admin.salvarQuestao(questaoNova()),
      primeiroIdQuestaoAdmin + 1,
    );

    final q = await linha('Questao', id);
    expect(q['sincronizado'], 0);
    expect(q['fonte'], fonteAutoral);
    expect(q['explicacao_gerada'], 0);
    final c = await conteudo();
    expect(c.questaoPorId(id)?.gabarito.letra, 'C');
    expect(c.questaoPorId(id)?.pendente, isTrue);
  });

  test('questão sem alternativa correta é recusada', () async {
    final semCorreta = questaoNova(correta: 'Z');
    await expectLater(
      admin.salvarQuestao(semCorreta),
      throwsA(
        isA<ErroAdmin>().having(
          (e) => e.campos.keys,
          'campos',
          contains('alternativas'),
        ),
      ),
    );
    await expectLater(
      admin.salvarQuestao(questaoNova(enunciado: ' ', dificuldade: 4)),
      throwsA(
        isA<ErroAdmin>().having(
          (e) => e.campos.keys,
          'campos',
          containsAll(['enunciado', 'dificuldade']),
        ),
      ),
    );
    await admin.excluirAssunto(1);
    await expectLater(
      admin.salvarQuestao(questaoNova()),
      throwsA(isA<ErroAdmin>()),
    );
  });

  test('editar questão preserva a dificuldade calibrada', () async {
    final db = await banco.db;
    final antes = (await linha('Questao', 1))['dificuldade_calibrada'];
    expect(antes, isNotNull);
    final atual = (await conteudo()).questaoPorId(1)!;
    await admin.salvarQuestao(
      Questao(
        id: 1,
        idAssunto: atual.idAssunto,
        enunciado: 'Novo enunciado',
        explicacao: atual.explicacao,
        dificuldade: 2,
        alternativas: questaoNova().alternativas,
      ),
    );
    final depois = await linha('Questao', 1);
    expect(depois['enunciado'], 'Novo enunciado');
    expect(depois['dificuldade_calibrada'], antes);
    final alternativas = await db.query('Alternativa', where: 'id_questao = 1');
    expect(alternativas, hasLength(5));
  });

  test('histórico de questão desativada continua abrindo', () async {
    final usuario = await UsuarioRepositorio(banco).criarVisitante();
    await HistoricoRepositorio(banco).registrar(
      idUsuario: usuario.id,
      idQuestao: 1,
      letra: 'A',
      acertou: false,
      tempoGasto: 5,
    );
    await admin.definirQuestaoAtiva(1, false);

    final c = await conteudo();
    expect(c.questoes.any((q) => q.id == 1), isFalse);
    expect(c.questaoPorId(1), isNotNull);
    final historico = await HistoricoRepositorio(banco).listar(usuario.id);
    expect(historico.single.idQuestao, 1);

    await admin.definirQuestaoAtiva(1, true);
    expect((await conteudo()).questoes.any((q) => q.id == 1), isTrue);
  });

  group('aplicarConteudo com pendentes', () {
    test('não sobrescreve matéria, assunto e questão pendentes', () async {
      await admin.editarMateria(1, 'Matemática local', 'matematica');
      await admin.editarAssunto(1, 'Potências local', '');
      final q = (await conteudo()).questaoPorId(2)!;
      await admin.salvarQuestao(
        Questao(
          id: 2,
          idAssunto: q.idAssunto,
          enunciado: 'Enunciado local',
          explicacao: q.explicacao,
          dificuldade: q.dificuldade,
          alternativas: questaoNova().alternativas,
        ),
      );

      await aplicarConteudo(await banco.db, lerPacoteInicial());

      expect((await linha('Materia', 1))['nome'], 'Matemática local');
      expect((await linha('Assunto', 1))['nome'], 'Potências local');
      expect((await linha('Questao', 2))['enunciado'], 'Enunciado local');
      // O que não está pendente volta ao pacote.
      expect((await linha('Materia', 2))['nome'], 'História');
    });

    test('não apaga aresta de matéria pendente', () async {
      await admin.criarAresta(
        const Dependencia(prerequisito: 1, dependente: 2, peso: 0.4),
      );
      await admin.removerAresta(2, 3);

      await aplicarConteudo(await banco.db, lerPacoteInicial());

      final arestas = await GrafoRepositorio(banco).listar();
      expect(
        arestas.any((d) => d.prerequisito == 1 && d.dependente == 2),
        isTrue,
      );
      expect(
        arestas.any((d) => d.prerequisito == 2 && d.dependente == 3),
        isFalse,
      );
      // Arestas de matérias sem pendência continuam vindo do pacote.
      expect(
        arestas.any((d) => d.prerequisito == 601 && d.dependente == 602),
        isTrue,
      );
    });

    test('lê ativo de matéria e assunto, ausente é ativo', () {
      final pacote = PacoteConteudo.deDocumentos(
        {'versao': 1},
        [
          {
            'id': 1,
            'nome': 'M',
            'area': 'matematica',
            'ativo': false,
            'assuntos': [
              {'id': 1, 'nome': 'A', 'ativo': false},
              {'id': 2, 'nome': 'B'},
            ],
          },
        ],
        const [],
      );
      expect(pacote.materias.single.ativo, isFalse);
      expect(pacote.assuntos.map((a) => a.ativo), [false, true]);
    });
  });

  test('pacote inicial ainda tem versão', () {
    expect(versaoPacoteInicial, greaterThan(0));
  });
}
