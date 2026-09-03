import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

class ResumoAdmin {
  final int materias;
  final int assuntos;
  final int dependencias;
  final int questoes;
  final int alunos;
  final int respostas;

  const ResumoAdmin({
    required this.materias,
    required this.assuntos,
    required this.dependencias,
    required this.questoes,
    required this.alunos,
    required this.respostas,
  });
}

/// RF11 — números do painel.
class AdminRepository {
  final Database _db;
  AdminRepository(this._db);

  Future<int> _conta(String sql) async =>
      Sqflite.firstIntValue(await _db.rawQuery(sql)) ?? 0;

  Future<ResumoAdmin> resumo() async => ResumoAdmin(
    materias: await _conta('SELECT COUNT(*) FROM Materia'),
    assuntos: await _conta('SELECT COUNT(*) FROM Assunto'),
    dependencias: await _conta('SELECT COUNT(*) FROM Grafo_Dependencia'),
    questoes: await _conta('SELECT COUNT(*) FROM Questao'),
    alunos: await _conta("SELECT COUNT(*) FROM Usuario WHERE tipo = 'aluno'"),
    respostas: await _conta('SELECT COUNT(*) FROM Historico_Estudo'),
  );
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(databaseProvider)),
);

final resumoAdminProvider = FutureProvider.autoDispose<ResumoAdmin>(
  (ref) => ref.watch(adminRepositoryProvider).resumo(),
);
