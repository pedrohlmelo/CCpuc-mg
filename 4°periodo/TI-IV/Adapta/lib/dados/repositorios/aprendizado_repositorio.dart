import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../banco/banco_local.dart';

/// Memória de um assunto como está gravada em `Nivel_Memoria`.
class NivelMemoria {
  final int idAssunto;
  final double retencao;
  final DateTime ultimoEstudo;
  final int qtdRevisoes;

  const NivelMemoria({
    required this.idAssunto,
    required this.retencao,
    required this.ultimoEstudo,
    required this.qtdRevisoes,
  });
}

/// `Nivel_Memoria` e `Proficiencia`. Toda escrita de progresso marca a linha
/// como pendente de sincronização.
class AprendizadoRepositorio {
  final BancoLocal _banco;
  AprendizadoRepositorio(this._banco);

  Future<List<NivelMemoria>> memorias(int idUsuario) async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Nivel_Memoria',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
    return [
      for (final l in linhas)
        NivelMemoria(
          idAssunto: l['id_assunto'] as int,
          retencao: l['retencao_atual'] as double,
          ultimoEstudo: DateTime.parse(l['data_ultimo_estudo'] as String),
          qtdRevisoes: l['qtd_revisoes'] as int,
        ),
    ];
  }

  Future<void> salvarMemoria(int idUsuario, NivelMemoria memoria) async {
    final db = await _banco.db;
    await db.insert('Nivel_Memoria', {
      'id_usuario': idUsuario,
      'id_assunto': memoria.idAssunto,
      'retencao_atual': memoria.retencao,
      'data_ultimo_estudo': memoria.ultimoEstudo.toIso8601String(),
      'qtd_revisoes': memoria.qtdRevisoes,
      'sincronizado': 0,
      'atualizado_em': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// θ de cada assunto, em logits.
  Future<Map<int, double>> proficiencias(int idUsuario) async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Proficiencia',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
    return {
      for (final l in linhas)
        l['id_assunto'] as int: l['nivel_estimado'] as double,
    };
  }

  Future<void> salvarProficiencia(
    int idUsuario,
    int idAssunto,
    double nivel,
  ) async {
    final db = await _banco.db;
    final agora = DateTime.now().toIso8601String();
    await db.insert('Proficiencia', {
      'id_usuario': idUsuario,
      'id_assunto': idAssunto,
      'nivel_estimado': nivel,
      'data_atualizacao': agora,
      'sincronizado': 0,
      'atualizado_em': agora,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Apaga memória e proficiência do usuário (ferramenta de demo).
  Future<void> limpar(int idUsuario) async {
    final db = await _banco.db;
    await db.delete(
      'Nivel_Memoria',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
    await db.delete(
      'Proficiencia',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }
}

final aprendizadoRepositorioProvider = Provider<AprendizadoRepositorio>(
  (ref) => AprendizadoRepositorio(ref.watch(bancoProvider)),
);
