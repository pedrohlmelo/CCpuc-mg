import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/assunto.dart';
import '../domain/materia.dart';

/// RF02 / RF11 — matérias e assuntos.
class MateriaRepository {
  final Database _db;
  MateriaRepository(this._db);

  Future<List<Materia>> listar() async {
    final linhas = await _db.query('Materia', orderBy: 'nome');
    return linhas.map(Materia.deMapa).toList();
  }

  Future<Materia> criar(String nome) async {
    final id = await _db.insert('Materia', {'nome': nome.trim()});
    return Materia(id: id, nome: nome.trim());
  }

  Future<void> remover(int id) =>
      _db.delete('Materia', where: 'id = ?', whereArgs: [id]);

  Future<List<Assunto>> listarAssuntos({int? idMateria}) async {
    final linhas = await _db.query(
      'Assunto',
      where: idMateria == null ? null : 'id_materia = ?',
      whereArgs: idMateria == null ? null : [idMateria],
      orderBy: 'nome',
    );
    return linhas.map(Assunto.deMapa).toList();
  }

  Future<Assunto> criarAssunto({
    required int idMateria,
    required String nome,
    String? descricao,
  }) async {
    final id = await _db.insert('Assunto', {
      'id_materia': idMateria,
      'nome': nome.trim(),
      'descricao': descricao,
    });
    return Assunto(
      id: id,
      idMateria: idMateria,
      nome: nome.trim(),
      descricao: descricao,
    );
  }
}

final materiaRepositoryProvider = Provider<MateriaRepository>(
  (ref) => MateriaRepository(ref.watch(databaseProvider)),
);

final materiasProvider = FutureProvider<List<Materia>>(
  (ref) => ref.watch(materiaRepositoryProvider).listar(),
);

final assuntosProvider = FutureProvider.family<List<Assunto>, int?>(
  (ref, idMateria) =>
      ref.watch(materiaRepositoryProvider).listarAssuntos(idMateria: idMateria),
);

/// Matéria escolhida pelo aluno para a sessão. `null` = estudo geral (RF02).
final materiaSelecionadaProvider = StateProvider<Materia?>((_) => null);
