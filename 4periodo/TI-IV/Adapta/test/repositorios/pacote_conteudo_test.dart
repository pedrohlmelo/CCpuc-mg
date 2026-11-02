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

    test('recusa ids repetidos', () {
      recusa(_pacote(questoes: [_questao(1), _questao(1)]));
      recusa(
        _pacote(
          assuntos: const [
            Assunto(id: 1, idMateria: 1, nome: 'a'),
            Assunto(id: 1, idMateria: 1, nome: 'b'),
          ],
        ),
      );
    });

    test('recusa questão sem exatamente uma alternativa correta', () {
      recusa(
        _pacote(
          questoes: [
            _questao(1, corretas: [false, false]),
          ],
        ),
      );
      recusa(
        _pacote(
          questoes: [
            _questao(1, corretas: [true, true]),
          ],
        ),
      );
    });

    test('mapa malformado vira PacoteInvalido', () {
      expect(
        () => PacoteConteudo.deMapas({'versao': 'dois'}, const []),
        throwsA(isA<PacoteInvalido>()),
      );
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

  test('migração 1 → 2 preserva o progresso', () async {
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
      lerAsset: lerAssetDoDisco,
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

  test('versão dos assets igual à salva não reaplica o pacote', () async {
    sqfliteFfiInit();
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    BancoLocal abrir() => BancoLocal(
      fabrica: databaseFactoryFfiNoIsolate,
      caminho: '${pasta.path}/adapta.db',
      lerAsset: lerAssetDoDisco,
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
