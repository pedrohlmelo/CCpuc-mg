import 'dart:io';

import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../apoio/app_teste.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('o banco nasce com todo o conteúdo do seed', () async {
    final banco = bancoDeTeste();
    final conteudo = await ConteudoRepositorio(banco).carregar();

    expect(conteudo.materias, hasLength(14));
    expect(conteudo.assuntosDaMateria(1), hasLength(20));
    expect(
      conteudo.questoes,
      hasLength((await pacoteDeTeste()).questoes.length),
    );
    for (final a in conteudo.assuntosDaMateria(1)) {
      expect(
        conteudo.questoes.where((q) => q.idAssunto == a.id).length,
        greaterThanOrEqualTo(3),
        reason: a.nome,
      );
    }
    await banco.fechar();
  });

  test('o pacote embutido passa na validação', () async {
    (await pacoteDeTeste()).validar();
  });

  test('toda imagem existe nos assets e tem descrição', () async {
    final questoes = (await pacoteDeTeste()).questoes;
    final comImagem = questoes.where((q) => q.imagemUrl != null).toList();
    expect(comImagem, isNotEmpty);
    for (final q in comImagem) {
      final caminho = q.imagemUrl!.replaceFirst('asset:', '');
      expect(File(caminho).existsSync(), isTrue, reason: caminho);
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

  test('banco de build antigo é guardado e recriado', () async {
    sqfliteFfiInit();
    final pasta = Directory.systemTemp.createTempSync('adapta');
    addTearDown(() => pasta.delete(recursive: true));
    final caminho = '${pasta.path}/adapta.db';
    final antigo = await databaseFactoryFfiNoIsolate.openDatabase(
      caminho,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE Usuario (id INTEGER PRIMARY KEY, nome TEXT, '
          'email TEXT NOT NULL, senha TEXT NOT NULL)',
        ),
      ),
    );
    await antigo.insert('Usuario', {
      'nome': 'Administrador',
      'email': 'a@b.c',
      'senha': 'x',
    });
    await antigo.close();

    final banco = BancoLocal(
      fabrica: databaseFactoryFfiNoIsolate,
      caminho: caminho,
      lerAsset: lerAssetDoDisco,
    );
    final usuario = await UsuarioRepositorio(banco).sessaoInicial();
    final conteudo = await ConteudoRepositorio(banco).carregar();
    await banco.fechar();

    expect(usuario.visitante, isTrue);
    expect(
      conteudo.questoes,
      hasLength((await pacoteDeTeste()).questoes.length),
    );
    expect(File('$caminho.antigo').existsSync(), isTrue);
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
