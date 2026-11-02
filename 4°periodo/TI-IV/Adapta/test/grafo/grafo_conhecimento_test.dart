import 'package:adapta/dados/banco/seed.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/grafo/grafo_conhecimento.dart';
import 'package:flutter_test/flutter_test.dart';

Dependencia d(int p, int q, [double w = 1]) =>
    Dependencia(prerequisito: p, dependente: q, peso: w);

void main() {
  // 1 → 2 → 4, 1 → 3 → 4, 4 → 5
  final losango = GrafoConhecimento(
    [1, 2, 3, 4, 5],
    [d(1, 2), d(1, 3), d(2, 4), d(3, 4), d(4, 5)],
  );

  test('o grafo do seed é um DAG conexo com todos os assuntos', () {
    final grafo = GrafoConhecimento(
      assuntosSeed.map((a) => a.id).toList(),
      dependenciasSeed,
    );
    expect(grafo.temCiclo, isFalse);
    expect(grafo.ordemTopologica(), hasLength(assuntosSeed.length));
  });

  test('detecta ciclo existente', () {
    expect(losango.temCiclo, isFalse);
    expect(
      GrafoConhecimento([1, 2, 3], [d(1, 2), d(2, 3), d(3, 1)]).temCiclo,
      isTrue,
    );
    expect(GrafoConhecimento([1], [d(1, 1)]).temCiclo, isTrue);
  });

  test('criariaCiclo recusa fechar o caminho e aceita o resto', () {
    expect(losango.criariaCiclo(5, 1), isTrue);
    expect(losango.caminho(1, 5), [1, 2, 4, 5]);
    expect(losango.criariaCiclo(2, 3), isFalse);
    expect(losango.criariaCiclo(3, 3), isTrue);
  });

  test('ordem topológica respeita toda aresta', () {
    final ordem = losango.ordemTopologica();
    for (final v in losango.vertices) {
      for (final q in losango.dependentes(v)) {
        expect(ordem.indexOf(v), lessThan(ordem.indexOf(q)));
      }
    }
  });

  test('camada é a maior distância até uma raiz', () {
    final grafo = GrafoConhecimento(
      [1, 2, 3, 4],
      [d(1, 2), d(2, 3), d(1, 3), d(3, 4)],
    );
    expect(grafo.camadas(), {1: 0, 2: 1, 3: 2, 4: 3});
  });

  test('causa raiz acha o pré-requisito mais fraco', () {
    final lacuna = losango.causaRaiz(5, {1: 0.9, 2: 0.2, 3: 0.45, 4: 0.8}, {});
    expect(lacuna?.idRaiz, 2);
    expect(lacuna?.forca, 0.2);
  });

  test('o peso da aresta pondera a causa raiz', () {
    final grafo = GrafoConhecimento([1, 2, 3], [d(1, 3, 0.1), d(2, 3, 1.0)]);
    expect(grafo.causaRaiz(3, {1: 0.1, 2: 0.4}, {})?.idRaiz, 2);
  });

  test('proficiência baixa também é lacuna; sem evidência, não há', () {
    expect(losango.causaRaiz(4, {2: 0.9}, {2: -3})?.idRaiz, 2);
    expect(losango.causaRaiz(5, {}, {}), isNull);
    expect(losango.causaRaiz(5, {4: 0.9, 3: 0.8}, {}), isNull);
  });

  test('esquecimento se propaga na proporção do peso', () {
    final grafo = GrafoConhecimento([1, 2, 3, 4], [d(1, 2, 1), d(2, 3, 0.5)]);
    final saida = grafo.propagarEsquecimento({1: 0.3, 2: 0.9, 3: 0.9});
    expect(saida[1], 0.3);
    expect(saida[2], closeTo(0.3, 1e-9));
    expect(saida[3], closeTo(0.65, 1e-9));
    expect(saida.containsKey(4), isFalse);
  });

  test('propagar não aumenta a retenção de ninguém', () {
    final saida = losango.propagarEsquecimento({1: 0.9, 2: 0.1});
    expect(saida[2], 0.1);
  });

  test('gargalos vêm por grau de saída', () {
    expect(losango.gargalos().first, 1);
    expect(losango.gargalos(), isNot(contains(5)));
  });
}
