import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../banco/banco_local.dart';
import '../modelos.dart';

class HistoricoRepositorio {
  final BancoLocal _banco;
  HistoricoRepositorio(this._banco);

  static const _uuid = Uuid();

  /// Respostas do usuário, da mais recente para a mais antiga.
  Future<List<Resposta>> listar(int idUsuario) async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Historico_Estudo',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'data DESC',
    );
    return [for (final l in linhas) _resposta(l)];
  }

  Resposta _resposta(Map<String, Object?> l) => Resposta(
    idQuestao: l['id_questao'] as int,
    letraEscolhida: l['letra_escolhida'] as String,
    acertou: l['acertou'] == 1,
    quando: DateTime.parse(l['data'] as String),
    tempoGasto: l['tempo_gasto'] as int,
  );

  Future<Resposta> registrar({
    required int idUsuario,
    required int idQuestao,
    required String letra,
    required bool acertou,
    required int tempoGasto,
  }) async {
    final db = await _banco.db;
    final agora = DateTime.now();
    final resposta = Resposta(
      idQuestao: idQuestao,
      letraEscolhida: letra,
      acertou: acertou,
      quando: agora,
      tempoGasto: tempoGasto,
    );
    await db.insert(
      'Historico_Estudo',
      _linha(_uuid.v4(), idUsuario, resposta, agora),
    );
    return resposta;
  }

  Map<String, Object?> _linha(
    String id,
    int idUsuario,
    Resposta r,
    DateTime agora,
  ) => {
    'id': id,
    'id_usuario': idUsuario,
    'id_questao': r.idQuestao,
    'letra_escolhida': r.letraEscolhida,
    'acertou': r.acertou ? 1 : 0,
    'data': r.quando.toIso8601String(),
    'tempo_gasto': r.tempoGasto,
    'sincronizado': 0,
    'atualizado_em': agora.toIso8601String(),
  };

  /// Troca o histórico do usuário por [respostas] (ferramenta de demo). Os ids
  /// são determinísticos: carregar de novo sobrescreve a cópia da nuvem em vez
  /// de duplicá-la.
  Future<void> substituir(
    int idUsuario,
    String prefixo,
    List<Resposta> respostas,
  ) async {
    final db = await _banco.db;
    final agora = DateTime.now();
    await db.transaction((txn) async {
      await txn.delete(
        'Historico_Estudo',
        where: 'id_usuario = ?',
        whereArgs: [idUsuario],
      );
      final lote = txn.batch();
      for (var i = 0; i < respostas.length; i++) {
        final id = _uuid.v5(Namespace.url.value, '$prefixo-$idUsuario-$i');
        lote.insert(
          'Historico_Estudo',
          _linha(id, idUsuario, respostas[i], agora),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await lote.commit(noResult: true);
    });
  }
}

final historicoRepositorioProvider = Provider<HistoricoRepositorio>(
  (ref) => HistoricoRepositorio(ref.watch(bancoProvider)),
);
