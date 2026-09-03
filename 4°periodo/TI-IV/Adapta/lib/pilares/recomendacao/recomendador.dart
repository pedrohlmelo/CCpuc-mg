import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/questoes/data/historico_repository.dart';
import '../../features/questoes/data/questao_repository.dart';
import '../../features/questoes/domain/questao.dart';

/// Pilar 1 — contrato do sistema de recomendação adaptativa (RF03, RF06).
///
/// Dado o aluno e um filtro opcional de matéria, devolve a próxima melhor
/// questão. `null` significa que não há mais questões elegíveis.
abstract class Recomendador {
  Future<Questao?> proximaQuestao({required int idUsuario, int? idMateria});
}

/// Implementação provisória: entrega, em ordem de dificuldade declarada, a
/// primeira questão que o aluno ainda não respondeu. Será substituída pelo
/// modelo treinado com o dataset sintético.
class RecomendadorSequencial implements Recomendador {
  final QuestaoRepository _questoes;
  final HistoricoRepository _historico;

  RecomendadorSequencial(this._questoes, this._historico);

  @override
  Future<Questao?> proximaQuestao({
    required int idUsuario,
    int? idMateria,
  }) async {
    final respondidas = await _historico.questoesRespondidas(idUsuario);
    final candidatas = await _questoes.listar(idMateria: idMateria);
    for (final q in candidatas) {
      if (!respondidas.contains(q.id)) return q;
    }
    return null;
  }
}

final recomendadorProvider = Provider<Recomendador>(
  (ref) => RecomendadorSequencial(
    ref.watch(questaoRepositoryProvider),
    ref.watch(historicoRepositoryProvider),
  ),
);
