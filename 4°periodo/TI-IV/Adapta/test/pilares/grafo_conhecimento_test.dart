import 'package:adapta/features/admin/data/grafo_repository.dart';
import 'package:adapta/pilares/grafo/grafo_conhecimento.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('GrafoConhecimento', () {
    late GrafoConhecimento g;

    setUp(() {
      // 1 → 2 → 4,  1 → 3 → 4,  5 → 4   (exemplo da memória)
      g = GrafoConhecimento()
        ..adicionarAresta(const Dependencia(prerequisito: 1, dependente: 2))
        ..adicionarAresta(const Dependencia(prerequisito: 1, dependente: 3))
        ..adicionarAresta(const Dependencia(prerequisito: 2, dependente: 4))
        ..adicionarAresta(const Dependencia(prerequisito: 3, dependente: 4))
        ..adicionarAresta(const Dependencia(prerequisito: 5, dependente: 4));
    });

    test('é DAG', () => expect(g.ehDag, isTrue));

    test('detecta aresta que fecharia ciclo', () {
      expect(g.criariaCiclo(4, 1), isTrue);
      expect(g.criariaCiclo(4, 4), isTrue);
      expect(g.criariaCiclo(5, 1), isFalse);
    });

    test('ordenação topológica respeita pré-requisitos', () {
      final ordem = g.ordenacaoTopologica();
      expect(ordem.length, 5);
      for (final d in g.arestas) {
        expect(
          ordem.indexOf(d.prerequisito),
          lessThan(ordem.indexOf(d.dependente)),
        );
      }
    });

    test(
      'pré-requisitos transitivos do mais próximo ao mais distante (RF09)',
      () {
        final pre = g.prerequisitosTransitivos(4);
        expect(pre.toSet(), {1, 2, 3, 5});
        expect(pre.indexOf(1), greaterThan(pre.indexOf(2)));
      },
    );

    test('grau de saída identifica gargalo', () {
      expect(g.grauSaida(1), 2);
      expect(g.grauSaida(4), 0);
    });

    test('ciclo faz ordenação topológica falhar', () {
      g.adicionarAresta(const Dependencia(prerequisito: 4, dependente: 1));
      expect(g.ehDag, isFalse);
    });
  });

  group('GrafoRepository', () {
    test('seed é um DAG e rejeita aresta cíclica', () async {
      final db = await bancoDeTeste();
      final repo = GrafoRepository(db);
      final grafo = await repo.carregar();
      expect(grafo.ehDag, isTrue);
      expect(grafo.quantidadeVertices, 7);

      // Logaritmo (5) → Potenciação (1) fecharia ciclo.
      await expectLater(
        () => repo.adicionar(const Dependencia(prerequisito: 5, dependente: 1)),
        throwsA(isA<ArestaCriaCiclo>()),
      );
      await db.close();
    });
  });
}
