import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../banco/banco_local.dart';
import '../modelos.dart';

class GrafoRepositorio {
  final BancoLocal _banco;
  GrafoRepositorio(this._banco);

  Future<List<Dependencia>> listar() async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Grafo_Dependencia',
      orderBy: 'id_prerequisito, id_dependente',
    );
    return [
      for (final l in linhas)
        Dependencia(
          prerequisito: l['id_prerequisito'] as int,
          dependente: l['id_dependente'] as int,
          peso: l['peso'] as double,
        ),
    ];
  }

  Future<void> adicionar(Dependencia aresta) async {
    final db = await _banco.db;
    await db.insert('Grafo_Dependencia', {
      'id_prerequisito': aresta.prerequisito,
      'id_dependente': aresta.dependente,
      'peso': aresta.peso,
    });
  }

  Future<void> remover(int prerequisito, int dependente) async {
    final db = await _banco.db;
    await db.delete(
      'Grafo_Dependencia',
      where: 'id_prerequisito = ? AND id_dependente = ?',
      whereArgs: [prerequisito, dependente],
    );
  }
}

final grafoRepositorioProvider = Provider<GrafoRepositorio>(
  (ref) => GrafoRepositorio(ref.watch(bancoProvider)),
);

final dependenciasProvider = FutureProvider<List<Dependencia>>(
  (ref) => ref.watch(grafoRepositorioProvider).listar(),
);
