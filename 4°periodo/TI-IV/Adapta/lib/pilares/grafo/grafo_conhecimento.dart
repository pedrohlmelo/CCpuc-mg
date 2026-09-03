import 'dart:collection';

/// Aresta `prerequisito → dependente` com peso (força da dependência).
class Dependencia {
  final int prerequisito;
  final int dependente;
  final double peso;

  const Dependencia({
    required this.prerequisito,
    required this.dependente,
    this.peso = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      other is Dependencia &&
      other.prerequisito == prerequisito &&
      other.dependente == dependente;

  @override
  int get hashCode => Object.hash(prerequisito, dependente);

  @override
  String toString() => '$prerequisito -> $dependente ($peso)';
}

/// Pilar 3 — grafo direcionado de pré-requisitos entre assuntos.
///
/// Lista de adjacência dupla: `_saida` para caminhar para frente
/// (propagação do esquecimento) e `_entrada` para caminhar para trás
/// (diagnóstico de causa-raiz, RF09). Vértices são `Assunto.id`.
class GrafoConhecimento {
  final Map<int, List<Dependencia>> _saida = {};
  final Map<int, List<Dependencia>> _entrada = {};

  Iterable<int> get vertices => _saida.keys;
  int get quantidadeVertices => _saida.length;
  Iterable<Dependencia> get arestas => _saida.values.expand((l) => l);

  void adicionarVertice(int id) {
    _saida.putIfAbsent(id, () => []);
    _entrada.putIfAbsent(id, () => []);
  }

  void adicionarAresta(Dependencia d) {
    adicionarVertice(d.prerequisito);
    adicionarVertice(d.dependente);
    _saida[d.prerequisito]!.add(d);
    _entrada[d.dependente]!.add(d);
  }

  /// Vizinhos diretos "para frente": o que depende de [id].
  List<Dependencia> dependentesDiretos(int id) => _saida[id] ?? const [];

  /// Vizinhos diretos "para trás": pré-requisitos imediatos de [id].
  List<Dependencia> prerequisitosDiretos(int id) => _entrada[id] ?? const [];

  /// Grau de saída — base para identificar gargalos.
  int grauSaida(int id) => dependentesDiretos(id).length;

  /// `true` se já existe caminho `dependente ~> prerequisito`; nesse caso
  /// inserir `prerequisito → dependente` fecharia um ciclo.
  bool criariaCiclo(int prerequisito, int dependente) {
    if (prerequisito == dependente) return true;
    return alcanca(dependente, prerequisito);
  }

  /// BFS para frente: existe caminho de [origem] até [alvo]?
  bool alcanca(int origem, int alvo) {
    final visitados = <int>{origem};
    final fila = Queue<int>()..add(origem);
    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      for (final d in dependentesDiretos(atual)) {
        if (d.dependente == alvo) return true;
        if (visitados.add(d.dependente)) fila.add(d.dependente);
      }
    }
    return false;
  }

  /// Todos os pré-requisitos (transitivos) de [id], do mais próximo ao mais
  /// distante. É a travessia usada pelo diagnóstico de causa-raiz (RF09).
  List<int> prerequisitosTransitivos(int id) {
    final visitados = <int>{};
    final ordem = <int>[];
    final fila = Queue<int>()..add(id);
    while (fila.isNotEmpty) {
      final atual = fila.removeFirst();
      for (final d in prerequisitosDiretos(atual)) {
        if (visitados.add(d.prerequisito)) {
          ordem.add(d.prerequisito);
          fila.add(d.prerequisito);
        }
      }
    }
    return ordem;
  }

  /// Ordenação topológica (Kahn). Lança [StateError] se houver ciclo.
  List<int> ordenacaoTopologica() {
    final grauEntrada = {for (final v in vertices) v: _entrada[v]!.length};
    final fila = Queue<int>()
      ..addAll(
        grauEntrada.entries.where((e) => e.value == 0).map((e) => e.key),
      );
    final ordem = <int>[];
    while (fila.isNotEmpty) {
      final v = fila.removeFirst();
      ordem.add(v);
      for (final d in dependentesDiretos(v)) {
        final restante = grauEntrada[d.dependente]! - 1;
        grauEntrada[d.dependente] = restante;
        if (restante == 0) fila.add(d.dependente);
      }
    }
    if (ordem.length != quantidadeVertices) {
      throw StateError('O grafo contém ciclo; não é um DAG.');
    }
    return ordem;
  }

  bool get ehDag {
    try {
      ordenacaoTopologica();
      return true;
    } on StateError {
      return false;
    }
  }
}
