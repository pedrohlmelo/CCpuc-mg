import '../dados/modelos.dart';
import '../dados/repositorios/conteudo_repositorio.dart';
import '../grafo/grafo_conhecimento.dart';
import 'modelo_proficiencia.dart';

/// Monta a fila de estudo (RF03), em memória e sem rede.
class MontadorFila {
  static const tamanho = 10;
  static const _revisoes = 3; // ~30% da fila
  static const _porCausaRaiz = 2;

  final Conteudo conteudo;
  final GrafoConhecimento grafo;
  final Map<int, double> retencoes;
  final Map<int, double> proficiencias;

  /// Da mais recente para a mais antiga.
  final List<Resposta> historico;

  const MontadorFila({
    required this.conteudo,
    required this.grafo,
    required this.retencoes,
    required this.proficiencias,
    required this.historico,
  });

  double _dificuldade(Questao q) =>
      q.dificuldadeCalibrada ?? (q.dificuldade - 2).toDouble();

  double _chance(Questao q) => ModeloProficiencia.probabilidadeAcerto(
    proficiencias[q.idAssunto] ?? 0,
    _dificuldade(q),
  );

  /// Mira em 70% de acerto; alivia depois de 2 erros, aperta depois de 3 acertos.
  double get _alvo {
    if (historico.length >= 2 && historico.take(2).every((r) => !r.acertou)) {
      return 0.80;
    }
    if (historico.length >= 3 && historico.take(3).every((r) => r.acertou)) {
      return 0.60;
    }
    return 0.70;
  }

  bool _vermelho(int id) =>
      estadoDaRetencao(retencoes[id]) == EstadoMemoria.critico;

  List<Questao> montar({int? idMateria, int? idCausaRaiz, DateTime? agora}) {
    final instante = agora ?? DateTime.now();
    final limite = instante.subtract(const Duration(hours: 24));
    final recentes = historico
        .where((r) => r.quando.isAfter(limite))
        .map((r) => r.idQuestao)
        .toSet();
    final respondidas = historico.map((r) => r.idQuestao).toSet();
    final alvo = _alvo;

    final noEscopo = conteudo.questoesDaMateria(idMateria);
    final posicao = {
      for (final (i, id) in grafo.ordemTopologica().indexed) id: i,
    };

    // 1. Elegíveis: nenhum pré-requisito vermelho, na ordem topológica.
    bool elegivel(int assunto) => !grafo.prerequisitos(assunto).any(_vermelho);

    int perto(Questao a, Questao b) {
      final porChance = (_chance(a) - alvo).abs().compareTo(
        (_chance(b) - alvo).abs(),
      );
      if (porChance != 0) return porChance;
      return (posicao[a.idAssunto] ?? 0).compareTo(posicao[b.idAssunto] ?? 0);
    }

    final fila = <Questao>[];
    void incluir(Iterable<Questao> questoes, int quantas) {
      var faltam = quantas;
      for (final q in questoes) {
        if (faltam == 0 || fila.length == tamanho) return;
        if (fila.any((f) => f.id == q.id)) continue;
        fila.add(q);
        faltam--;
      }
    }

    final novas = noEscopo.where((q) => !recentes.contains(q.id)).toList()
      ..sort(perto);

    // 2. Causa raiz.
    if (idCausaRaiz != null) {
      incluir(novas.where((q) => q.idAssunto == idCausaRaiz), _porCausaRaiz);
    }

    // 3. Revisões: vermelhos e amarelos, o mais urgente primeiro.
    final urgentes =
        retencoes.keys
            .where(
              (id) =>
                  estadoDaRetencao(retencoes[id]) !=
                      EstadoMemoria.consolidado &&
                  elegivel(id),
            )
            .toList()
          ..sort((a, b) => retencoes[a]!.compareTo(retencoes[b]!));
    for (final id in urgentes) {
      final vagas =
          _revisoes - fila.where((q) => q.idAssunto != idCausaRaiz).length;
      if (vagas <= 0) break;
      incluir(novas.where((q) => q.idAssunto == id), 1);
    }

    // 4. O resto: primeiro o que nunca foi visto, perto da chance-alvo.
    final elegiveis = novas.where((q) => elegivel(q.idAssunto));
    incluir(elegiveis.where((q) => !respondidas.contains(q.id)), tamanho);
    incluir(elegiveis, tamanho);

    // Sobras, para a fila nunca ficar vazia.
    incluir(novas, tamanho);
    incluir(noEscopo, tamanho);
    return fila;
  }
}
