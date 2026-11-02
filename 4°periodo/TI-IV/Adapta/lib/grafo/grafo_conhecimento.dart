import 'dart:collection';
import 'dart:math';

import '../dados/modelos.dart';

/// Abaixo deste nível um pré-requisito conta como lacuna.
const limiarLacuna = 0.5;

/// Pré-requisito fraco que explica a dificuldade em [idAssunto].
class Lacuna {
  final int idAssunto;
  final int idRaiz;
  final double forca;
  const Lacuna({
    required this.idAssunto,
    required this.idRaiz,
    required this.forca,
  });
}

/// Grafo de conhecimento: vértices são assuntos e cada aresta vai do
/// pré-requisito para o dependente. Guarda a lista de adjacência nos dois
/// sentidos.
class GrafoConhecimento {
  final List<int> vertices;
  final Map<int, Map<int, double>> _saida = {};
  final Map<int, Map<int, double>> _entrada = {};

  GrafoConhecimento(this.vertices, List<Dependencia> arestas) {
    for (final v in vertices) {
      _saida[v] = {};
      _entrada[v] = {};
    }
    for (final a in arestas) {
      (_saida[a.prerequisito] ??= {})[a.dependente] = a.peso;
      (_entrada[a.dependente] ??= {})[a.prerequisito] = a.peso;
    }
  }

  Iterable<int> prerequisitos(int id) => _entrada[id]?.keys ?? const [];

  Iterable<int> dependentes(int id) => _saida[id]?.keys ?? const [];

  double? peso(int prerequisito, int dependente) =>
      _saida[prerequisito]?[dependente];

  /// DFS com três cores: chegar a um vértice em andamento é um ciclo.
  bool get temCiclo {
    final andamento = <int>{};
    final concluidos = <int>{};

    bool visitar(int v) {
      if (andamento.contains(v)) return true;
      if (!concluidos.add(v)) return false;
      andamento.add(v);
      final achou = dependentes(v).any(visitar);
      andamento.remove(v);
      return achou;
    }

    return vertices.any((v) => !concluidos.contains(v) && visitar(v));
  }

  /// Caminho de [origem] até [destino] por DFS, ou nulo se não existir.
  List<int>? caminho(int origem, int destino) {
    final visitados = <int>{};

    List<int>? visitar(int v) {
      if (v == destino) return [v];
      if (!visitados.add(v)) return null;
      for (final proximo in dependentes(v)) {
        final resto = visitar(proximo);
        if (resto != null) return [v, ...resto];
      }
      return null;
    }

    return visitar(origem);
  }

  /// A aresta `pre → dep` fecha ciclo se já existe caminho de `dep` até `pre`.
  bool criariaCiclo(int pre, int dep) => caminho(dep, pre) != null;

  /// Kahn. Com ciclo, devolve só os vértices que conseguiu ordenar.
  List<int> ordemTopologica() {
    final graus = {for (final v in vertices) v: prerequisitos(v).length};
    final fila = Queue.of(vertices.where((v) => graus[v] == 0));
    final ordem = <int>[];
    while (fila.isNotEmpty) {
      final v = fila.removeFirst();
      ordem.add(v);
      for (final d in dependentes(v)) {
        graus[d] = graus[d]! - 1;
        if (graus[d] == 0) fila.add(d);
      }
    }
    return ordem;
  }

  /// Camada de cada vértice: a maior distância a partir de uma raiz.
  Map<int, int> camadas() {
    final camada = <int, int>{};
    for (final v in ordemTopologica()) {
      camada[v] = prerequisitos(
        v,
      ).fold(0, (maior, p) => max(maior, (camada[p] ?? 0) + 1));
    }
    return camada;
  }

  /// BFS reversa a partir de [idAssunto] pelos pré-requisitos. Entre os que
  /// estão abaixo do [limiar], devolve o mais fraco, ponderando o quanto falta
  /// pelo produto dos pesos do caminho: pré-requisito distante ou de aresta
  /// leve explica menos.
  ///
  /// [proficiencias] vem em logits (θ). A força do assunto é o menor valor
  /// entre retenção e P(acerto). Assunto nunca estudado não é evidência.
  Lacuna? causaRaiz(
    int idAssunto,
    Map<int, double> retencoes,
    Map<int, double> proficiencias, {
    double limiar = limiarLacuna,
  }) {
    final influencia = <int, double>{idAssunto: 1};
    final fila = Queue.of([idAssunto]);
    Lacuna? melhor;
    var maiorFraqueza = 0.0;

    while (fila.isNotEmpty) {
      final v = fila.removeFirst();
      for (final p in prerequisitos(v)) {
        final acumulada = influencia[v]! * peso(p, v)!;
        if (influencia.containsKey(p)) {
          influencia[p] = max(influencia[p]!, acumulada);
          continue;
        }
        influencia[p] = acumulada;
        fila.add(p);

        final forca = _forca(p, retencoes, proficiencias);
        if (forca == null || forca >= limiar) continue;
        final fraqueza = (limiar - forca) * acumulada;
        if (fraqueza > maiorFraqueza) {
          maiorFraqueza = fraqueza;
          melhor = Lacuna(idAssunto: idAssunto, idRaiz: p, forca: forca);
        }
      }
    }
    return melhor;
  }

  double? _forca(
    int id,
    Map<int, double> retencoes,
    Map<int, double> proficiencias,
  ) {
    final retencao = retencoes[id];
    final theta = proficiencias[id];
    if (retencao == null && theta == null) return null;
    final acerto = theta == null ? 1.0 : 1 / (1 + exp(-theta));
    return min(retencao ?? 1.0, acerto);
  }

  /// Percorre para a frente: o dependente não pode ser lembrado muito melhor
  /// que o pré-requisito. O teto é `peso·r_pre + (1 − peso)`: com peso 1 ele é
  /// a própria retenção do pré-requisito; com peso 0 não há limite. Assuntos
  /// não estudados continuam fora do mapa.
  Map<int, double> propagarEsquecimento(Map<int, double> retencoes) {
    final saida = Map.of(retencoes);
    for (final v in ordemTopologica()) {
      final atual = saida[v];
      if (atual == null) continue;
      var limite = atual;
      for (final p in prerequisitos(v)) {
        final rPre = saida[p];
        if (rPre == null) continue;
        final w = peso(p, v)!;
        limite = min(limite, w * rPre + (1 - w));
      }
      saida[v] = limite;
    }
    return saida;
  }

  /// Vértices com mais dependentes primeiro (grau de saída).
  List<int> gargalos() {
    final lista = vertices.where((v) => dependentes(v).isNotEmpty).toList();
    lista.sort(
      (a, b) => dependentes(b).length.compareTo(dependentes(a).length),
    );
    return lista;
  }
}
