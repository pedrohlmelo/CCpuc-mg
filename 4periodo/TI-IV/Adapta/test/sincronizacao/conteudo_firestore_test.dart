import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/preferencias.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/historico_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:adapta/dados/sincronizacao/servico_sincronizacao.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

/// Simula a queda da rede depois de a segunda página ser aplicada.
class _PreferenciasQueFalham extends Preferencias {
  var gravacoes = 0;

  @override
  Future<void> gravarUltimaSincronizacaoConteudo(String atualizadoEm) async {
    if (++gravacoes == 2) throw Exception('rede caiu');
    await super.gravarUltimaSincronizacaoConteudo(atualizadoEm);
  }
}

void main() {
  late BancoLocal banco;
  late FakeFirebaseFirestore firestore;
  late ConectividadeFalsa rede;
  late ServicoSincronizacao servico;
  const preferencias = Preferencias();
  var relogio = 0;

  String carimbo() =>
      '2026-11-02T12:00:${(relogio ~/ 1000).toString().padLeft(2, '0')}.'
      '${(relogio++ % 1000).toString().padLeft(3, '0')}Z';

  Map<String, dynamic> questao(int id, {bool ativo = true, String? texto}) => {
    'id': id,
    'materia': 1,
    'assunto': 1,
    'dificuldade': 2,
    'enunciado': texto ?? 'Enunciado $id',
    'explicacao': 'x',
    'imagem': null,
    'imagem_descricao': null,
    'fonte': 'ENEM 2023, questão 1',
    'explicacao_gerada': true,
    'revisado': false,
    'ativo': ativo,
    'atualizado_em': carimbo(),
    'alternativas': [
      {'letra': 'A', 'texto': 'a', 'correta': true},
      {'letra': 'B', 'texto': 'b', 'correta': false},
    ],
  };

  Future<void> publicar(int versao, List<Map<String, dynamic>> questoes) async {
    for (final q in questoes) {
      await firestore.collection('questoes').doc('${q['id']}').set(q);
    }
    await firestore.collection('meta').doc('conteudo').set({
      'versao': versao,
      'dependencias_entre_materias': const [],
    });
  }

  Future<int> linhas(String onde) async {
    final db = await banco.db;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Questao WHERE $onde',
    );
    return r.first['n'] as int;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    relogio = 0;
    banco = bancoDeTeste();
    firestore = FakeFirebaseFirestore();
    rede = ConectividadeFalsa(conectado: true);
    servico = ServicoSincronizacao(banco, firestore, preferencias, rede);
    await firestore.collection('materias').doc('1').set({
      'id': 1,
      'nome': 'Matemática',
      'area': 'matematica',
      'assuntos': [
        {'id': 1, 'nome': 'Potenciação', 'descricao': ''},
      ],
      'dependencias': const [],
    });
  });

  tearDown(() => banco.fechar());

  test('a primeira sincronização baixa tudo, em mais de uma página', () async {
    final total = tamanhoPaginaConteudo + 5;
    await publicar(7, [for (var i = 0; i < total; i++) questao(9000000 + i)]);

    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);

    expect(await linhas('id BETWEEN 9000000 AND 9000999'), total);
    expect(await preferencias.lerVersaoBanco(), 7);
  });

  test('o pacote inicial com a mesma versão não impede o download', () async {
    await banco.db;
    final versaoDoPacote = await preferencias.lerVersaoConteudo();
    await publicar(versaoDoPacote!, [questao(9000000)]);

    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);
    expect(await linhas('id = 9000000'), 1);
  });

  test('a segunda sincronização traz só o que mudou', () async {
    await publicar(7, [questao(9000000), questao(9000001)]);
    await servico.baixarConteudo();
    final db = await banco.db;
    await db.update('Questao', {'enunciado': 'local'}, where: 'id = 9000000');

    await publicar(8, [questao(9000001, texto: 'novo')]);
    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);

    expect(await linhas("id = 9000000 AND enunciado = 'local'"), 1);
    expect(await linhas("id = 9000001 AND enunciado = 'novo'"), 1);
  });

  test('versão igual não baixa nada', () async {
    await publicar(7, [questao(9000000)]);
    await servico.baixarConteudo();
    await firestore.collection('questoes').doc('9000001').set(questao(9000001));

    expect(await servico.baixarConteudo(), ResultadoConteudo.igual);
    expect(await linhas('id = 9000001'), 0);
  });

  test('questão desativada some do conteúdo', () async {
    await publicar(7, [questao(9000000)]);
    await servico.baixarConteudo();
    await publicar(8, [questao(9000000, ativo: false)]);
    await servico.baixarConteudo();

    final conteudo = await ConteudoRepositorio(banco).carregar();
    expect(conteudo.questoes.map((q) => q.id), isNot(contains(9000000)));
    expect(conteudo.questaoPorId(9000000)?.ativo, isFalse);
  });

  test('questão importada e ainda sem assunto é ignorada', () async {
    await publicar(7, [
      {...questao(9000000), 'assunto': null},
      questao(9000001),
    ]);
    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);
    expect(await linhas('id = 9000000'), 0);
    expect(await linhas('id = 9000001'), 1);
  });

  test('o progresso local fica intacto', () async {
    final usuario = await UsuarioRepositorio(banco).criarVisitante(uid: 'u1');
    await HistoricoRepositorio(banco).registrar(
      idUsuario: usuario.id,
      idQuestao: 1,
      letra: 'B',
      acertou: true,
      tempoGasto: 9,
    );
    final db = await banco.db;
    final antes = await db.query('Historico_Estudo');

    await publicar(7, [
      {...questao(1), 'enunciado': 'corrigido'},
    ]);
    await servico.baixarConteudo();

    expect(await db.query('Historico_Estudo'), antes);
    expect(await linhas("id = 1 AND enunciado = 'corrigido'"), 1);
  });

  test('falha no meio mantém o que entrou, e a próxima continua', () async {
    final total = tamanhoPaginaConteudo + 5;
    await publicar(7, [for (var i = 0; i < total; i++) questao(9000000 + i)]);
    final comFalha = ServicoSincronizacao(
      banco,
      firestore,
      _PreferenciasQueFalham(),
      rede,
    );

    expect(await comFalha.baixarConteudo(), ResultadoConteudo.falhou);
    expect(await preferencias.lerVersaoBanco(), isNull);
    expect(await linhas('id BETWEEN 9000000 AND 9000999'), total);

    // A primeira página não é baixada de novo.
    final db = await banco.db;
    await db.update('Questao', {'enunciado': 'local'}, where: 'id = 9000000');
    await db.delete('Alternativa', where: 'id_questao = 9000304');
    await db.delete('Questao', where: 'id = 9000304');

    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);
    expect(await linhas("id = 9000000 AND enunciado = 'local'"), 1);
    expect(await linhas('id = 9000304'), 1);
    expect(await preferencias.lerVersaoBanco(), 7);
  });

  test('offline não baixa', () async {
    await publicar(7, [questao(9000000)]);
    rede.conectado = false;
    expect(await servico.baixarConteudo(), ResultadoConteudo.falhou);
    expect(await linhas('id = 9000000'), 0);
  });

  test('sem conteúdo publicado, nada muda', () async {
    expect(await servico.baixarConteudo(), ResultadoConteudo.igual);
  });

  test('pacote aplicado de novo reinicia o download', () async {
    await preferencias.gravarVersaoBanco(7);
    await preferencias.gravarUltimaSincronizacaoConteudo('x');
    await preferencias.reiniciarDownloadConteudo();
    expect(await preferencias.lerVersaoBanco(), isNull);
    expect(await preferencias.lerUltimaSincronizacaoConteudo(), isNull);
  });
}
