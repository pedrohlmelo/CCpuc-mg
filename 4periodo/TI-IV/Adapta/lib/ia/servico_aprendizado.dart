import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/banco/historicos_demo.dart';
import '../dados/estado_app.dart';
import '../dados/modelos.dart';
import '../dados/repositorios/aprendizado_repositorio.dart';
import '../dados/repositorios/conteudo_repositorio.dart';
import '../dados/repositorios/grafo_repositorio.dart';
import '../dados/repositorios/historico_repositorio.dart';
import '../grafo/grafo_conhecimento.dart';
import 'modelo_esquecimento.dart';
import 'modelo_proficiencia.dart';
import 'montador_fila.dart';

/// Abaixo desta diferença a memória não é regravada: abrir o app não deve
/// gerar pendências de sincronização sem mudança real.
const _mudancaMinima = 0.01;

/// Quantas respostas recentes contam para achar o assunto com mais erros.
const _janelaErros = 30;

/// "Seus erros em X apontam para uma lacuna em Y".
class AvisoLacuna {
  final String assunto;
  final String raiz;
  final int idRaiz;
  const AvisoLacuna({
    required this.assunto,
    required this.raiz,
    required this.idRaiz,
  });
}

/// "Você tem N% de chance de esquecer X amanhã".
class AlertaEsquecimento {
  final SaudeAssunto assunto;
  final int chance;
  const AlertaEsquecimento({required this.assunto, required this.chance});
}

/// O que a home e o mapa mostram sobre a memória do aluno.
class Panorama {
  final List<SaudeAssunto> saude;
  final Map<int, double> retencoes;
  final Map<int, double> proficiencias;
  final AvisoLacuna? lacuna;
  final AlertaEsquecimento? alerta;

  const Panorama({
    required this.saude,
    required this.retencoes,
    required this.proficiencias,
    required this.lacuna,
    required this.alerta,
  });

  static const vazio = Panorama(
    saude: [],
    retencoes: {},
    proficiencias: {},
    lacuna: null,
    alerta: null,
  );
}

/// Liga os modelos ao banco: recalcula a memória, atualiza a proficiência e
/// monta a fila.
class ServicoAprendizado {
  final ConteudoRepositorio _conteudo;
  final GrafoRepositorio _grafo;
  final HistoricoRepositorio _historico;
  final AprendizadoRepositorio _aprendizado;
  final ModeloEsquecimento _esquecimento;
  final ModeloProficiencia _proficiencia;

  ServicoAprendizado(
    this._conteudo,
    this._grafo,
    this._historico,
    this._aprendizado,
    this._esquecimento,
    this._proficiencia,
  );

  /// Retenção de cada assunto estudado daqui a [folga] dias, já com o
  /// esquecimento propagado pelo grafo.
  Map<int, double> _prever(
    List<_Estudo> estudos,
    GrafoConhecimento grafo,
    double folga,
  ) => grafo.propagarEsquecimento({
    for (final e in estudos)
      e.idAssunto: _esquecimento.probabilidadeLembrar(
        dias: e.dias + folga,
        qtdRevisoes: e.diasDeEstudo.length,
        dificuldade: e.dificuldade,
        taxaAcerto: e.taxaAcerto,
      ),
  });

  /// Recalcula tudo a partir do histórico, que é a fonte do esquecimento, e
  /// grava em `Nivel_Memoria`.
  Future<Panorama> recalcular(Usuario usuario, {DateTime? agora}) async {
    final instante = agora ?? DateTime.now();
    final conteudo = await _conteudo.carregar();
    final grafo = await _montarGrafo(conteudo);
    final respostas = await _historico.listar(usuario.id);
    if (respostas.isEmpty) return Panorama.vazio;

    final estudos = _agrupar(respostas, conteudo, instante);
    final retencoes = _prever(estudos, grafo, 0);
    final amanha = _prever(estudos, grafo, 1);
    await _gravarMemorias(usuario, estudos, retencoes);
    final proficiencias = await _aprendizado.proficiencias(usuario.id);

    final saude = [
      for (final e in estudos)
        SaudeAssunto(
          idAssunto: e.idAssunto,
          nome: conteudo.nomeDoAssunto(e.idAssunto),
          retencao: retencoes[e.idAssunto]!,
          estado: estadoDaRetencao(retencoes[e.idAssunto]),
        ),
    ]..sort((a, b) => a.retencao.compareTo(b.retencao));

    final emRisco = saude
        .where((s) => s.estado != EstadoMemoria.consolidado)
        .firstOrNull;
    return Panorama(
      saude: saude,
      retencoes: retencoes,
      proficiencias: proficiencias,
      lacuna: _acharLacuna(
        respostas,
        conteudo,
        grafo,
        retencoes,
        proficiencias,
      ),
      alerta: emRisco == null
          ? null
          : AlertaEsquecimento(
              assunto: emRisco,
              chance: ((1 - amanha[emRisco.idAssunto]!) * 100).round().clamp(
                1,
                99,
              ),
            ),
    );
  }

  Future<GrafoConhecimento> _montarGrafo(Conteudo conteudo) async =>
      GrafoConhecimento(
        conteudo.assuntos.map((a) => a.id).toList(),
        await _grafo.listar(),
      );

  List<_Estudo> _agrupar(
    List<Resposta> respostas,
    Conteudo conteudo,
    DateTime agora,
  ) {
    final porAssunto = <int, _Estudo>{};
    for (final r in respostas) {
      final questao = conteudo.questaoPorId(r.idQuestao);
      if (questao == null) continue;
      (porAssunto[questao.idAssunto] ??= _Estudo(
        questao.idAssunto,
        agora,
      )).somar(r, questao);
    }
    return porAssunto.values.toList();
  }

  Future<void> _gravarMemorias(
    Usuario usuario,
    List<_Estudo> estudos,
    Map<int, double> retencoes,
  ) async {
    final atuais = {
      for (final m in await _aprendizado.memorias(usuario.id)) m.idAssunto: m,
    };
    for (final e in estudos) {
      final retencao = retencoes[e.idAssunto]!;
      final atual = atuais[e.idAssunto];
      final igual =
          atual != null &&
          (atual.retencao - retencao).abs() < _mudancaMinima &&
          atual.qtdRevisoes == e.diasDeEstudo.length &&
          atual.ultimoEstudo == e.ultimo;
      if (igual) continue;
      await _aprendizado.salvarMemoria(
        usuario.id,
        NivelMemoria(
          idAssunto: e.idAssunto,
          retencao: retencao,
          ultimoEstudo: e.ultimo!,
          qtdRevisoes: e.diasDeEstudo.length,
        ),
      );
    }
  }

  /// Procura, a partir do assunto com mais erros recentes, o primeiro que
  /// tenha uma causa raiz nos pré-requisitos.
  AvisoLacuna? _acharLacuna(
    List<Resposta> respostas,
    Conteudo conteudo,
    GrafoConhecimento grafo,
    Map<int, double> retencoes,
    Map<int, double> proficiencias,
  ) {
    final erros = <int, int>{};
    for (final r in respostas.take(_janelaErros).where((r) => !r.acertou)) {
      final assunto = conteudo.questaoPorId(r.idQuestao)?.idAssunto;
      if (assunto != null) erros[assunto] = (erros[assunto] ?? 0) + 1;
    }
    final ordem = erros.keys.toList()
      ..sort((a, b) => erros[b]!.compareTo(erros[a]!));
    for (final id in ordem) {
      final lacuna = grafo.causaRaiz(id, retencoes, proficiencias);
      if (lacuna != null) {
        return AvisoLacuna(
          assunto: conteudo.nomeDoAssunto(id),
          raiz: conteudo.nomeDoAssunto(lacuna.idRaiz),
          idRaiz: lacuna.idRaiz,
        );
      }
    }
    return null;
  }

  /// Atualiza θ do assunto e b da questão depois de uma resposta.
  Future<void> registrarResposta(
    Usuario usuario,
    Questao questao,
    bool acertou,
  ) async {
    final thetas = await _aprendizado.proficiencias(usuario.id);
    final passo = ModeloProficiencia.atualizar(
      thetas[questao.idAssunto] ?? 0,
      _dificuldadeDe(questao),
      acertou,
    );
    await _aprendizado.salvarProficiencia(
      usuario.id,
      questao.idAssunto,
      passo.theta,
    );
    await _conteudo.gravarDificuldadeCalibrada(questao.id, passo.b);
  }

  double _dificuldadeDe(Questao q) =>
      q.dificuldadeCalibrada ??
      _proficiencia.dificuldades[q.id] ??
      (q.dificuldade - 2).toDouble();

  /// Fila da próxima sessão.
  Future<List<Questao>> montarFila(Usuario usuario, {int? idMateria}) async {
    final panorama = await recalcular(usuario);
    final conteudo = await _conteudo.carregar();
    return MontadorFila(
      conteudo: conteudo,
      grafo: await _montarGrafo(conteudo),
      retencoes: panorama.retencoes,
      proficiencias: await _aprendizado.proficiencias(usuario.id),
      historico: await _historico.listar(usuario.id),
    ).montar(idMateria: idMateria, idCausaRaiz: panorama.lacuna?.idRaiz);
  }

  /// Usado nos testes: troca o progresso do usuário pelo histórico do
  /// [perfil] e reconstrói a proficiência resposta a resposta.
  Future<void> carregarDemo(Usuario usuario, PerfilDemo perfil) async {
    final conteudo = await _conteudo.carregar();
    final respostas = historicoDemo(perfil, DateTime.now());
    await _aprendizado.limpar(usuario.id);
    await _historico.substituir(usuario.id, perfil.name, respostas);

    final thetas = <int, double>{};
    for (final r in respostas) {
      final questao = conteudo.questaoPorId(r.idQuestao);
      if (questao == null) continue;
      final id = questao.idAssunto;
      thetas[id] = ModeloProficiencia.atualizar(
        thetas[id] ?? 0,
        _dificuldadeDe(questao),
        r.acertou,
      ).theta;
    }
    for (final MapEntry(key: id, value: theta) in thetas.entries) {
      await _aprendizado.salvarProficiencia(usuario.id, id, theta);
    }
    await recalcular(usuario);
  }
}

/// Resumo do estudo de um assunto, tirado do histórico.
class _Estudo {
  final int idAssunto;
  final DateTime agora;
  final diasDeEstudo = <String>{};
  final _dificuldades = <int, int>{};
  int _acertos = 0;
  int _total = 0;
  DateTime? ultimo;

  _Estudo(this.idAssunto, this.agora);

  void somar(Resposta r, Questao q) {
    _total++;
    if (r.acertou) _acertos++;
    _dificuldades[q.id] = q.dificuldade;
    diasDeEstudo.add(r.quando.toIso8601String().substring(0, 10));
    if (ultimo == null || r.quando.isAfter(ultimo!)) ultimo = r.quando;
  }

  double get dias => agora.difference(ultimo!).inMinutes / (60 * 24);

  double get dificuldade =>
      _dificuldades.values.reduce((a, b) => a + b) / _dificuldades.length;

  /// Mesma suavização do treino (`ia/gerar_dataset.py`).
  double get taxaAcerto => (_acertos + 1) / (_total + 2);
}

/// Os dois modelos, lidos dos assets uma vez. A dificuldade treinada entra no
/// banco só onde a questão ainda não foi calibrada.
final servicoAprendizadoProvider = FutureProvider<ServicoAprendizado>((
  ref,
) async {
  final esquecimento = ModeloEsquecimento.deJson(
    jsonDecode(await rootBundle.loadString('assets/modelos/esquecimento.json'))
        as Map<String, dynamic>,
  );
  final proficiencia = ModeloProficiencia.deJson(
    jsonDecode(await rootBundle.loadString('assets/modelos/dificuldades.json'))
        as Map<String, dynamic>,
  );
  final conteudo = ref.watch(conteudoRepositorioProvider);
  await conteudo.preencherDificuldades(proficiencia.dificuldades);
  return ServicoAprendizado(
    conteudo,
    ref.watch(grafoRepositorioProvider),
    ref.watch(historicoRepositorioProvider),
    ref.watch(aprendizadoRepositorioProvider),
    esquecimento,
    proficiencia,
  );
});

/// Sobe a cada resposta, para a home e o mapa recalcularem.
final versaoAprendizadoProvider = StateProvider<int>((_) => 0);

final panoramaProvider = FutureProvider<Panorama>((ref) async {
  ref.watch(versaoAprendizadoProvider);
  final usuario = ref.watch(usuarioProvider);
  if (usuario == null) return Panorama.vazio;
  final servico = await ref.watch(servicoAprendizadoProvider.future);
  return servico.recalcular(usuario);
});

final retencoesProvider = FutureProvider<Map<int, double>>(
  (ref) async => (await ref.watch(panoramaProvider.future)).retencoes,
);
