import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/historico_estudo.dart';

/// RF04 / RF10 — registro de respostas. Dataset dos Pilares 1 e 2.
class HistoricoRepository {
  final Database _db;
  HistoricoRepository(this._db);

  Future<HistoricoEstudo> registrar({
    required int idUsuario,
    required int idQuestao,
    required bool acertou,
    int tempoGastoSegundos = 0,
    DateTime? data,
  }) async {
    final quando = data ?? DateTime.now();
    final id = await _db.insert('Historico_Estudo', {
      'id_usuario': idUsuario,
      'id_questao': idQuestao,
      'acertou': acertou ? 1 : 0,
      'data': quando.toIso8601String(),
      'tempo_gasto': tempoGastoSegundos,
    });
    return HistoricoEstudo(
      id: id,
      idUsuario: idUsuario,
      idQuestao: idQuestao,
      acertou: acertou,
      data: quando,
      tempoGastoSegundos: tempoGastoSegundos,
    );
  }

  Future<List<HistoricoEstudo>> listarDoUsuario(int idUsuario) async {
    final linhas = await _db.query(
      'Historico_Estudo',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'data DESC',
    );
    return linhas.map(HistoricoEstudo.deMapa).toList();
  }

  /// IDs das questões que o usuário já respondeu.
  Future<Set<int>> questoesRespondidas(int idUsuario) async {
    final linhas = await _db.query(
      'Historico_Estudo',
      columns: ['DISTINCT id_questao'],
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
    return linhas.map((l) => l['id_questao'] as int).toSet();
  }
}

final historicoRepositoryProvider = Provider<HistoricoRepository>(
  (ref) => HistoricoRepository(ref.watch(databaseProvider)),
);
