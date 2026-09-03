import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../pilares/grafo/grafo_conhecimento.dart';

class ArestaCriaCiclo implements Exception {
  @override
  String toString() =>
      'Essa dependência criaria um ciclo. O grafo precisa ser um DAG.';
}

/// RF11 — arestas do grafo de pré-requisitos. Persistência em
/// `Grafo_Dependencia`; a validação de ciclo é responsabilidade do app.
class GrafoRepository {
  final Database _db;
  GrafoRepository(this._db);

  Future<List<Dependencia>> listar({int? idMateria}) async {
    final linhas = idMateria == null
        ? await _db.query('Grafo_Dependencia')
        : await _db.rawQuery(
            '''
            SELECT g.* FROM Grafo_Dependencia g
            JOIN Assunto a ON a.id = g.id_dependente
            WHERE a.id_materia = ?
          ''',
            [idMateria],
          );
    return linhas
        .map(
          (l) => Dependencia(
            prerequisito: l['id_prerequisito'] as int,
            dependente: l['id_dependente'] as int,
            peso: (l['peso'] as num).toDouble(),
          ),
        )
        .toList();
  }

  /// Carrega o grafo inteiro em memória (dezenas de vértices no MVP).
  Future<GrafoConhecimento> carregar() async {
    final grafo = GrafoConhecimento();
    for (final a in await _db.query('Assunto', columns: ['id'])) {
      grafo.adicionarVertice(a['id'] as int);
    }
    for (final d in await listar()) {
      grafo.adicionarAresta(d);
    }
    return grafo;
  }

  /// Insere a aresta se ela não fechar ciclo; senão lança [ArestaCriaCiclo].
  Future<void> adicionar(Dependencia d) async {
    final grafo = await carregar();
    if (grafo.criariaCiclo(d.prerequisito, d.dependente)) {
      throw ArestaCriaCiclo();
    }
    await _db.insert('Grafo_Dependencia', {
      'id_prerequisito': d.prerequisito,
      'id_dependente': d.dependente,
      'peso': d.peso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remover(int prerequisito, int dependente) => _db.delete(
    'Grafo_Dependencia',
    where: 'id_prerequisito = ? AND id_dependente = ?',
    whereArgs: [prerequisito, dependente],
  );
}

final grafoRepositoryProvider = Provider<GrafoRepository>(
  (ref) => GrafoRepository(ref.watch(databaseProvider)),
);
