import 'dart:convert';
import 'dart:io';

import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/banco/historicos_demo.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/repositorios/aprendizado_repositorio.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/grafo_repositorio.dart';
import 'package:adapta/dados/repositorios/historico_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:adapta/dados/sincronizacao/servico_sincronizacao.dart';
import 'package:adapta/dados/preferencias.dart';
import 'package:adapta/ia/modelo_esquecimento.dart';
import 'package:adapta/ia/modelo_proficiencia.dart';
import 'package:adapta/ia/servico_aprendizado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

Map<String, dynamic> lerJson(String caminho) =>
    jsonDecode(File(caminho).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late BancoLocal banco;
  late ServicoAprendizado servico;
  late Usuario usuario;
  late ModeloProficiencia proficiencia;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    proficiencia = ModeloProficiencia.deJson(
      lerJson('assets/modelos/dificuldades.json'),
    );
    final conteudo = ConteudoRepositorio(banco);
    await conteudo.preencherDificuldades(proficiencia.dificuldades);
    servico = ServicoAprendizado(
      conteudo,
      GrafoRepositorio(banco),
      HistoricoRepositorio(banco),
      AprendizadoRepositorio(banco),
      ModeloEsquecimento.deJson(lerJson('assets/modelos/esquecimento.json')),
      proficiencia,
    );
    usuario = await UsuarioRepositorio(banco).criarVisitante();
  });

  tearDown(() => banco.fechar());

  group('modelos', () {
    final modelo = ModeloEsquecimento.deJson(
      lerJson('assets/modelos/esquecimento.json'),
    );

    double lembrar({double dias = 3, int qtd = 3, double taxa = 0.7}) =>
        modelo.probabilidadeLembrar(
          dias: dias,
          qtdRevisoes: qtd,
          dificuldade: 2,
          taxaAcerto: taxa,
        );

    test('lembrar cai com o tempo e sobe com revisões e acertos', () {
      expect(lembrar(dias: 30), lessThan(lembrar(dias: 1)));
      expect(lembrar(qtd: 8), greaterThan(lembrar(qtd: 1)));
      expect(lembrar(taxa: 0.9), greaterThan(lembrar(taxa: 0.2)));
    });

    test('toda questão do seed tem dificuldade treinada', () {
      expect(proficiencia.dificuldades, hasLength(44));
    });

    test('Rasch: acertar sobe θ e baixa b', () {
      expect(ModeloProficiencia.probabilidadeAcerto(0, 0), 0.5);
      final passo = ModeloProficiencia.atualizar(0, 0, true);
      expect(passo.theta, closeTo(0.2, 1e-9));
      expect(passo.b, closeTo(-0.025, 1e-9));
      expect(ModeloProficiencia.atualizar(0, 0, false).theta, lessThan(0));
    });
  });

  test('sem histórico o panorama é vazio e a fila não', () async {
    final panorama = await servico.recalcular(usuario);
    expect(panorama.saude, isEmpty);
    expect(await servico.montarFila(usuario), hasLength(10));
  });

  group('demonstração', () {
    test('Ana: Logaritmo vermelho, lacuna em Potenciação', () async {
      await servico.carregarDemo(usuario, PerfilDemo.ana);
      final p = await servico.recalcular(usuario);

      expect(estadoDaRetencao(p.retencoes[5]), EstadoMemoria.critico);
      expect(estadoDaRetencao(p.retencoes[1]), EstadoMemoria.critico);
      expect(p.lacuna?.assunto, 'Logaritmo');
      expect(p.lacuna?.raiz, 'Potenciação');
      expect(p.alerta, isNotNull);
    });

    test('Bruno: Funções esquecida, básicos consolidados', () async {
      await servico.carregarDemo(usuario, PerfilDemo.bruno);
      final p = await servico.recalcular(usuario);

      expect(
        estadoDaRetencao(p.retencoes[4]),
        isNot(EstadoMemoria.consolidado),
      );
      expect(estadoDaRetencao(p.retencoes[8]), EstadoMemoria.consolidado);
      expect(p.saude.first.retencao, lessThan(p.retencoes[8]!));
    });

    test('filas de Ana e Bruno são diferentes', () async {
      final bruno = await UsuarioRepositorio(banco).criarVisitante();
      await servico.carregarDemo(usuario, PerfilDemo.ana);
      await servico.carregarDemo(bruno, PerfilDemo.bruno);

      final filaAna = await servico.montarFila(usuario);
      final filaBruno = await servico.montarFila(bruno);

      expect(filaAna.map((q) => q.id), isNot(filaBruno.map((q) => q.id)));
      expect(filaAna.where((q) => q.idAssunto == 1), isNotEmpty);
      expect(filaAna.map((q) => q.id).toSet(), hasLength(filaAna.length));
    });

    test('a fila da Ana não traz assunto com pré-requisito vermelho', () async {
      await servico.carregarDemo(usuario, PerfilDemo.ana);
      final fila = await servico.montarFila(usuario);
      expect(fila.where((q) => q.idAssunto == 5), isEmpty);
    });

    test('recalcular de novo não cria pendências novas', () async {
      final sincronizacao = ServicoSincronizacao(
        banco,
        null,
        const Preferencias(),
        ConectividadeFalsa(),
      );
      await servico.carregarDemo(usuario, PerfilDemo.ana);
      final db = await banco.db;
      await db.update('Nivel_Memoria', {'sincronizado': 1});
      final antes = await sincronizacao.contarPendentes(usuario.id);

      await servico.recalcular(usuario);

      expect(await sincronizacao.contarPendentes(usuario.id), antes);
    });
  });

  test('respeita a matéria escolhida e nunca fica vazia', () async {
    await servico.carregarDemo(usuario, PerfilDemo.ana);
    final conteudo = await ConteudoRepositorio(banco).carregar();
    final fila = await servico.montarFila(usuario, idMateria: 2);
    expect(fila, isNotEmpty);
    for (final q in fila) {
      expect(conteudo.assuntoPorId(q.idAssunto)!.idMateria, 2);
    }
  });

  test('evita repetir questões das últimas 24 h', () async {
    final historico = HistoricoRepositorio(banco);
    final primeira = await servico.montarFila(usuario);
    await historico.registrar(
      idUsuario: usuario.id,
      idQuestao: primeira.first.id,
      letra: 'A',
      acertou: false,
      tempoGasto: 5,
    );
    final segunda = await servico.montarFila(usuario);
    expect(segunda.map((q) => q.id), isNot(contains(primeira.first.id)));
  });

  test('responder atualiza proficiência e dificuldade calibrada', () async {
    final conteudo = await ConteudoRepositorio(banco).carregar();
    final questao = conteudo.questaoPorId(1)!;
    await servico.registrarResposta(usuario, questao, true);

    final thetas = await AprendizadoRepositorio(
      banco,
    ).proficiencias(usuario.id);
    expect(thetas[1], greaterThan(0));
    final depois = await ConteudoRepositorio(banco).carregar();
    expect(
      depois.questaoPorId(1)!.dificuldadeCalibrada,
      lessThan(questao.dificuldadeCalibrada!),
    );
  });

  test('a fila sai em menos de 2 s', () async {
    await servico.carregarDemo(usuario, PerfilDemo.bruno);
    final cronometro = Stopwatch()..start();
    await servico.montarFila(usuario);
    expect(cronometro.elapsedMilliseconds, lessThan(2000));
  });
}
