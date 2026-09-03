import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/alternativa.dart';
import '../domain/questao.dart';

/// RF04 / RF05 / RF11 — banco de questões.
class QuestaoRepository {
  final Database _db;
  QuestaoRepository(this._db);

  Future<Questao?> buscarPorId(int id) async {
    final linhas = await _db.query(
      'Questao',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Questao.deMapa(
      linhas.first,
      alternativas: await _alternativasDe(id),
    );
  }

  /// Questões de uma matéria (ou de todas, se `idMateria == null`).
  Future<List<Questao>> listar({int? idMateria, int? idAssunto}) async {
    final where = <String>[];
    final args = <Object>[];
    if (idMateria != null) {
      where.add('a.id_materia = ?');
      args.add(idMateria);
    }
    if (idAssunto != null) {
      where.add('q.id_assunto = ?');
      args.add(idAssunto);
    }
    final linhas = await _db.rawQuery('''
      SELECT q.* FROM Questao q
      JOIN Assunto a ON a.id = q.id_assunto
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY q.dificuldade, q.id
    ''', args);
    return [
      for (final l in linhas)
        Questao.deMapa(l, alternativas: await _alternativasDe(l['id'] as int)),
    ];
  }

  Future<Questao> criar({
    required int idAssunto,
    required String enunciado,
    String? explicacao,
    int dificuldade = 1,
    required List<({String letra, String texto, bool correta})> alternativas,
  }) async {
    assert(
      alternativas.where((a) => a.correta).length == 1,
      'Toda questão precisa de exatamente uma alternativa correta.',
    );
    return _db.transaction((txn) async {
      final id = await txn.insert('Questao', {
        'id_assunto': idAssunto,
        'enunciado': enunciado,
        'explicacao': explicacao,
        'dificuldade': dificuldade,
      });
      for (final alt in alternativas) {
        await txn.insert('Alternativa', {
          'id_questao': id,
          'letra': alt.letra,
          'texto': alt.texto,
          'correta': alt.correta ? 1 : 0,
        });
      }
      final linhas = await txn.query(
        'Alternativa',
        where: 'id_questao = ?',
        whereArgs: [id],
        orderBy: 'letra',
      );
      return Questao(
        id: id,
        idAssunto: idAssunto,
        enunciado: enunciado,
        explicacao: explicacao,
        dificuldade: dificuldade,
        alternativas: linhas.map(Alternativa.deMapa).toList(),
      );
    });
  }

  Future<List<Alternativa>> _alternativasDe(int idQuestao) async {
    final linhas = await _db.query(
      'Alternativa',
      where: 'id_questao = ?',
      whereArgs: [idQuestao],
      orderBy: 'letra',
    );
    return linhas.map(Alternativa.deMapa).toList();
  }
}

final questaoRepositoryProvider = Provider<QuestaoRepository>(
  (ref) => QuestaoRepository(ref.watch(databaseProvider)),
);
