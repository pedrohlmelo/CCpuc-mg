import 'dart:io';

import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/banco/pacote_conteudo.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../apoio/app_teste.dart';

/// Esquema da versão 1, como ficou nos aparelhos que já usam o app.
const _esquemaV1 = [
  "CREATE TABLE Usuario (id INTEGER PRIMARY KEY AUTOINCREMENT, uid_firebase "
      "TEXT UNIQUE, nome TEXT NOT NULL, email TEXT, tipo TEXT NOT NULL "
      "DEFAULT 'aluno')",
  'CREATE TABLE Materia (id INTEGER PRIMARY KEY, nome TEXT NOT NULL)',
  'CREATE TABLE Assunto (id INTEGER PRIMARY KEY, id_materia INTEGER NOT NULL, '
      "nome TEXT NOT NULL, descricao TEXT NOT NULL DEFAULT '')",
  'CREATE TABLE Grafo_Dependencia (id_prerequisito INTEGER NOT NULL, '
      'id_dependente INTEGER NOT NULL, peso REAL NOT NULL, '
      'PRIMARY KEY (id_prerequisito, id_dependente))',
  'CREATE TABLE Questao (id INTEGER PRIMARY KEY, id_assunto INTEGER NOT NULL, '
      'enunciado TEXT NOT NULL, explicacao TEXT NOT NULL, dificuldade INTEGER '
      'NOT NULL, dificuldade_calibrada REAL, imagem_url TEXT, imagem_local '
      'TEXT, imagem_descricao TEXT)',
  'CREATE TABLE Alternativa (id INTEGER PRIMARY KEY AUTOINCREMENT, id_questao '
      'INTEGER NOT NULL, letra TEXT NOT NULL, texto TEXT, correta INTEGER NOT '
      'NULL, imagem_url TEXT, imagem_local TEXT, imagem_descricao TEXT)',
  'CREATE TABLE Historico_Estudo (id TEXT PRIMARY KEY, id_usuario INTEGER NOT '
      'NULL, id_questao INTEGER NOT NULL, letra_escolhida TEXT NOT NULL, '
      'acertou INTEGER NOT NULL, data TEXT NOT NULL, tempo_gasto INTEGER NOT '
      'NULL, sincronizado INTEGER NOT NULL DEFAULT 0, atualizado_em TEXT NOT '
      'NULL)',
  'CREATE TABLE Nivel_Memoria (id_usuario INTEGER NOT NULL, id_assunto INTEGER '
      'NOT NULL, retencao_atual REAL NOT NULL, data_ultimo_estudo TEXT NOT '
      'NULL, qtd_revisoes INTEGER NOT NULL, sincronizado INTEGER NOT NULL '
      'DEFAULT 0, atualizado_em TEXT NOT NULL, PRIMARY KEY (id_usuario, '
      'id_assunto))',
  'CREATE TABLE Proficiencia (id_usuario INTEGER NOT NULL, id_assunto INTEGER '
      'NOT NULL, nivel_estimado REAL NOT NULL, data_atualizacao TEXT NOT NULL, '
      'sincronizado INTEGER NOT NULL DEFAULT 0, atualizado_em TEXT NOT NULL, '
      'PRIMARY KEY (id_usuario, id_assunto))',
];

Questao _questao(int id, {int idAssunto = 1, List<bool>? corretas}) => Questao(
  id: id,
  idAssunto: idAssunto,
  enunciado: 'e',
  explicacao: 'x',
  dificuldade: 2,
  alternativas: [
    for (final (i, c) in (corretas ?? [true, false]).indexed)
      Alternativa(letra: 'ABCDE'[i], texto: 't', correta: c),
  ],
);

PacoteConteudo _pacote({
  List<Dependencia> dependencias = const [],
  List<Questao>? questoes,
  List<Assunto>? assuntos,
}) => PacoteConteudo(
  versao: 9,
  materias: const [Materia(id: 1, nome: 'M')],
  assuntos:
      assuntos ??
      const [
        Assunto(id: 1, idMateria: 1, nome: 'a'),
        Assunto(id: 2, idMateria: 1, nome: 'b'),
      ],
  dependencias: dependencias,
  questoes: questoes ?? [_questao(1)],
);

Dependencia _d(int p, int q) => Dependencia(prerequisito: p, dependente: q);

Future<int> _contar(Database db, String tabela) async =>
    (await db.rawQuery('SELECT COUNT(*) AS n FROM $tabela')).first['n'] as int;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('validação', () {
    void recusa(PacoteConteudo pacote) =>
        expect(pacote.validar, throwsA(isA<PacoteInvalido>()));

    test('recusa ciclo', () {
      recusa(_pacote(dependencias: [_d(1, 2), _d(2, 1)]));
    });

    test('recusa aresta para assunto inexistente', () {
      recusa(_pacote(dependencias: [_d(1, 99)]));
    });

    test('recusa assuntos repetidos', () {
      recusa(
        _pacote(
          assuntos: const [
            Assunto(id: 1, idMateria: 1, nome: 'a'),
            Assunto(id: 1, idMateria: 1, nome: 'b'),
          ],
        ),
      );
    });

    test('documento de matéria malformado vira PacoteInvalido', () {
      expect(
        () =>
            PacoteConteudo.deDocumentos({'versao': 'dois'}, const [], const []),
        throwsA(isA<PacoteInvalido>()),
      );
    });

    test('questão inválida é descartada sem derrubar as outras', () {
      final validas = _pacote(
        questoes: [
          _questao(1),
          _questao(1),
          _questao(2, idAssunto: 99),
          _questao(3, corretas: [false, false]),
          _questao(4, corretas: [true, true]),
          _questao(5),
        ],
      ).questoesValidas({1, 2});
      expect(validas.map((q) => q.id), [1, 5]);
    });

    test('questão malformada não entra no pacote', () {
      final pacote = PacoteConteudo.deDocumentos(
        {'versao': 1},
        const [],
        const [
          {'id': 1, 'assunto': null},
        ],
      );
      expect(pacote.questoes, isEmpty);
    });
  });

  test('pacote com ciclo não altera o banco', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    final antes = await _contar(db, 'Grafo_Dependencia');
    await expectLater(
      aplicarConteudo(db, _pacote(dependencias: [_d(1, 2), _d(2, 1)])),
      throwsA(isA<PacoteInvalido>()),
    );
    expect(await _contar(db, 'Grafo_Dependencia'), antes);
    await banco.fechar();
  });

  test('questão inválida não entra no banco, e as válidas entram', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    await aplicarConteudo(
      db,
      _pacote(
        questoes: [
          _questao(900),
          _questao(901, corretas: [false, false]),
        ],
      ),
    );
    expect(await db.query('Questao', where: 'id = 900'), hasLength(1));
    expect(await db.query('Questao', where: 'id = 901'), isEmpty);
    await banco.fechar();
  });

  test(
    'página só com questões usa os assuntos do banco e mantém o grafo',
    () async {
      final banco = bancoDeTeste();
      final db = await banco.db;
      final arestas = await _contar(db, 'Grafo_Dependencia');
      expect(arestas, greaterThan(0));

      await aplicarConteudo(
        db,
        PacoteConteudo(
          versao: 9,
          materias: const [],
          assuntos: const [],
          dependencias: const [],
          questoes: [_questao(900, idAssunto: 2)],
        ),
      );

      expect(await db.query('Questao', where: 'id = 900'), hasLength(1));
      expect(await _contar(db, 'Grafo_Dependencia'), arestas);
      await banco.fechar();
    },
  );

  test(
    'questão inativa some do conteúdo, mas o histórico ainda a acha',
    () async {
      final banco = bancoDeTeste();
      final db = await banco.db;
      await aplicarConteudo(
        db,
        _pacote(
          questoes: [
            Questao(
              id: 1,
              idAssunto: 1,
              enunciado: 'e',
              explicacao: 'x',
              dificuldade: 1,
              ativo: false,
              alternativas: const [
                Alternativa(letra: 'A', texto: 't', correta: true),
              ],
            ),
          ],
        ),
      );

      final conteudo = await ConteudoRepositorio(banco).carregar();
      expect(conteudo.questoes.map((q) => q.id), isNot(contains(1)));
      expect(
        conteudo.questoesDaMateria(1).map((q) => q.id),
        isNot(contains(1)),
      );
      expect(conteudo.questaoPorId(1)?.ativo, isFalse);
      expect(await _contar(db, 'Questao'), greaterThan(0));
      await banco.fechar();
    },
  );

  test('dificuldade da IA só preenche a questão ainda não calibrada', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    await db.update('Questao', {'dificuldade_calibrada': 0.7}, where: 'id = 1');
    await db.update('Questao', {
      'dificuldade_calibrada': null,
    }, where: 'id = 2');
    Questao comB(int id) => Questao(
      id: id,
      idAssunto: 1,
      enunciado: 'e',
      explicacao: 'x',
      dificuldade: 1,
      dificuldadeIrt: -1.5,
      alternativas: const [Alternativa(letra: 'A', texto: 't', correta: true)],
    );

    await aplicarConteudo(db, _pacote(questoes: [comB(1), comB(2)]));

    Future<Object?> b(int id) async => (await db.query(
      'Questao',
      where: 'id = ?',
      whereArgs: [id],
    )).single['dificuldade_calibrada'];
    expect(await b(1), 0.7);
    expect(await b(2), -1.5);
    await banco.fechar();
  });

  test('aplicar o mesmo pacote duas vezes não duplica nada', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    final pacote = await pacoteDeTeste();
    Future<List<int>> contagens() async => [
      for (final t in [
        'Materia',
        'Assunto',
        'Questao',
        'Alternativa',
        'Grafo_Dependencia',
      ])
        await _contar(db, t),
    ];
    final idsAntes = await db.query('Alternativa', orderBy: 'id');
    final antes = await contagens();

    await aplicarConteudo(db, pacote);
    await aplicarConteudo(db, pacote);

    expect(await contagens(), antes);
    expect(await db.query('Alternativa', orderBy: 'id'), idsAntes);
    await banco.fechar();
  });

  test('preserva dificuldade calibrada e imagem local', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    await db.update('Questao', {
      'dificuldade_calibrada': 0.7,
      'imagem_local': '/tmp/q1.jpg',
    }, where: 'id = 1');

    await aplicarConteudo(db, await pacoteDeTeste());

    final linha = (await db.query('Questao', where: 'id = 1')).single;
    expect(linha['dificuldade_calibrada'], 0.7);
    expect(linha['imagem_local'], '/tmp/q1.jpg');
    await banco.fechar();
  });

  test('alternativa que saiu do pacote é removida', () async {
    final banco = bancoDeTeste();
    final db = await banco.db;
    final pacote = await pacoteDeTeste();
    await aplicarConteudo(
      db,
      PacoteConteudo(
        versao: 9,
        materias: pacote.materias,
        assuntos: pacote.assuntos,
        dependencias: pacote.dependencias,
        questoes: [_questao(1)],
      ),
    );
    final letras = await db.query('Alternativa', where: 'id_questao = 1');
    expect(letras.map((l) => l['letra']), unorderedEquals(['A', 'B']));
    await banco.fechar();
  });

  test('o conteúdo novo traz área, fonte e revisão', () async {
    final banco = bancoDeTeste();
    final conteudo = await ConteudoRepositorio(banco).carregar();
    expect(conteudo.materiaPorId(1)?.area, 'matematica');
    expect(conteudo.materiaPorId(2)?.area, 'humanas');
    final questao = conteudo.questaoPorId(1)!;
    expect(questao.fonte, 'Autoral — Adapta');
    expect(questao.revisado, isTrue);
    expect(questao.explicacaoGerada, isFalse);
    await banco.fechar();
  });

  test('só a questão gerada e não revisada recebe o aviso', () async {
    final banco = bancoDeTeste();
    final conteudo = await ConteudoRepositorio(banco).carregar();
    expect(conteudo.questaoPorId(1)!.explicacaoNaoRevisada, isFalse);
    final enem = conteudo.questoes.firstWhere(
      (q) => q.fonte!.startsWith('ENEM'),
    );
    expect(enem.explicacaoNaoRevisada, isTrue);
    await banco.fechar();
  });

  test('migração 1 → 3 preserva o progresso', () async {
    sqfliteFfiInit();
    SharedPreferences.setMockInitialValues({
      'seed_concluido': true,
      'versao_conteudo': 1,
    });
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    final caminho = '${pasta.path}/adapta.db';

    final v1 = await databaseFactoryFfiNoIsolate.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          for (final comando in _esquemaV1) {
            await db.execute(comando);
          }
        },
      ),
    );
    await v1.insert('Usuario', {'id': 1, 'uid_firebase': 'u', 'nome': 'Ana'});
    await v1.insert('Materia', {'id': 1, 'nome': 'Matemática'});
    await v1.insert('Assunto', {'id': 1, 'id_materia': 1, 'nome': 'Velho'});
    await v1.insert('Questao', {
      'id': 1,
      'id_assunto': 1,
      'enunciado': 'velho',
      'explicacao': 'velha',
      'dificuldade': 1,
      'dificuldade_calibrada': 0.3,
    });
    final idAlternativa = await v1.insert('Alternativa', {
      'id_questao': 1,
      'letra': 'A',
      'texto': 'velho',
      'correta': 0,
    });
    await v1.insert('Historico_Estudo', {
      'id': 'h1',
      'id_usuario': 1,
      'id_questao': 1,
      'letra_escolhida': 'A',
      'acertou': 0,
      'data': '2026-11-01',
      'tempo_gasto': 30,
      'atualizado_em': '2026-11-01',
    });
    await v1.insert('Nivel_Memoria', {
      'id_usuario': 1,
      'id_assunto': 1,
      'retencao_atual': 0.5,
      'data_ultimo_estudo': '2026-11-01',
      'qtd_revisoes': 2,
      'atualizado_em': '2026-11-01',
    });
    await v1.insert('Proficiencia', {
      'id_usuario': 1,
      'id_assunto': 1,
      'nivel_estimado': 0.4,
      'data_atualizacao': '2026-11-01',
      'atualizado_em': '2026-11-01',
    });
    await v1.close();

    final banco = BancoLocal(
      fabrica: databaseFactoryFfiNoIsolate,
      caminho: caminho,
    );
    final db = await banco.db;
    final pacote = await pacoteDeTeste();

    expect(await db.getVersion(), BancoLocal.versao);
    expect(await _contar(db, 'Historico_Estudo'), 1);
    expect((await db.query('Nivel_Memoria')).single['retencao_atual'], 0.5);
    expect((await db.query('Proficiencia')).single['nivel_estimado'], 0.4);

    expect(await _contar(db, 'Questao'), pacote.questoes.length);
    final questao = (await db.query('Questao', where: 'id = 1')).single;
    expect(questao['enunciado'], isNot('velho'));
    expect(questao['ativo'], 1);
    expect(questao['dificuldade_calibrada'], 0.3);
    final alternativa = await db.query(
      'Alternativa',
      where: 'id_questao = 1 AND letra = ?',
      whereArgs: ['A'],
    );
    expect(alternativa.single['id'], idAlternativa);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('versao_conteudo'), pacote.versao);
    await banco.fechar();
  });

  /// Volta o banco recém-criado ao esquema da versão [versao].
  Future<void> rebaixar(Database db, int versao) async {
    if (versao < 4) {
      for (final c in ['ativo', 'sincronizado', 'atualizado_em']) {
        await db.execute('ALTER TABLE Materia DROP COLUMN $c');
      }
      await db.execute('ALTER TABLE Assunto DROP COLUMN ativo');
      for (final c in ['sincronizado', 'atualizado_em']) {
        await db.execute('ALTER TABLE Questao DROP COLUMN $c');
      }
    }
    if (versao < 3) await db.execute('ALTER TABLE Questao DROP COLUMN ativo');
    await db.setVersion(versao);
  }

  test('migração 3 → 4 cria as colunas do painel sem pendentes', () async {
    sqfliteFfiInit();
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    final caminho = '${pasta.path}/adapta.db';
    BancoLocal abrir() =>
        BancoLocal(fabrica: databaseFactoryFfiNoIsolate, caminho: caminho);

    final atual = abrir();
    await rebaixar(await atual.db, 3);
    await atual.fechar();

    final migrado = abrir();
    final novo = await migrado.db;
    expect(await novo.getVersion(), 4);
    for (final tabela in ['Materia', 'Questao']) {
      final pendentes = await novo.rawQuery(
        'SELECT COUNT(*) AS n FROM $tabela WHERE sincronizado = 0',
      );
      expect(pendentes.first['n'], 0);
    }
    final inativos = await novo.rawQuery(
      'SELECT COUNT(*) AS n FROM Assunto WHERE ativo = 0',
    );
    expect(inativos.first['n'], 0);
    await migrado.fechar();
  });

  test('migração 2 → 4 ativa as questões e mantém o conteúdo', () async {
    sqfliteFfiInit();
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    final caminho = '${pasta.path}/adapta.db';
    BancoLocal abrir() =>
        BancoLocal(fabrica: databaseFactoryFfiNoIsolate, caminho: caminho);

    final atual = abrir();
    final db = await atual.db;
    await rebaixar(db, 2);
    final questoes = await _contar(db, 'Questao');
    await atual.fechar();

    final migrado = abrir();
    final novo = await migrado.db;
    expect(await novo.getVersion(), BancoLocal.versao);
    final ativas = await novo.rawQuery(
      'SELECT COUNT(*) AS n FROM Questao WHERE ativo = 1',
    );
    expect(ativas.first['n'], questoes);
    await migrado.fechar();
  });

  test('versão dos assets igual à salva não reaplica o pacote', () async {
    sqfliteFfiInit();
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    BancoLocal abrir() => BancoLocal(
      fabrica: databaseFactoryFfiNoIsolate,
      caminho: '${pasta.path}/adapta.db',
    );

    final primeiro = abrir();
    await (await primeiro.db).update('Materia', {
      'nome': 'Editada',
    }, where: 'id = 1');
    await primeiro.fechar();

    final segundo = abrir();
    final linha = (await (await segundo.db).query(
      'Materia',
      where: 'id = 1',
    )).single;
    expect(linha['nome'], 'Editada');
    await segundo.fechar();
  });
}
