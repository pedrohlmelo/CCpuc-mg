import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../pilares/esquecimento/previsor_esquecimento.dart';
import '../../autenticacao/application/sessao_controller.dart';
import '../../materias/data/materia_repository.dart';

/// Linha do painel de esquecimento (RF07).
class SaudeAssunto {
  final int idAssunto;
  final String nome;
  final double retencao;
  final SaudeMemoria saude;
  final int diasDesdeUltimoEstudo;

  const SaudeAssunto({
    required this.idAssunto,
    required this.nome,
    required this.retencao,
    required this.saude,
    required this.diasDesdeUltimoEstudo,
  });
}

class ResumoAluno {
  final int respondidas;
  final int acertos;
  final List<SaudeAssunto> assuntos;

  const ResumoAluno({
    required this.respondidas,
    required this.acertos,
    required this.assuntos,
  });

  double get taxaAcerto => respondidas == 0 ? 0 : acertos / respondidas;
  List<SaudeAssunto> get emRisco => assuntos
      .where(
        (a) =>
            a.saude == SaudeMemoria.critico || a.saude == SaudeMemoria.emRisco,
      )
      .toList();
}

/// Agrega o histórico por assunto e passa pelo previsor (stub por enquanto).
/// Quando o Pilar 2 real chegar, só a implementação do previsor muda.
final resumoAlunoProvider = FutureProvider.autoDispose<ResumoAluno>((
  ref,
) async {
  final usuario = ref.watch(sessaoProvider);
  if (usuario == null) {
    return const ResumoAluno(respondidas: 0, acertos: 0, assuntos: []);
  }
  final materia = ref.watch(materiaSelecionadaProvider);
  final db = ref.watch(databaseProvider);
  final previsor = ref.watch(previsorEsquecimentoProvider);

  final linhas = await db.rawQuery(
    '''
    SELECT a.id            AS id_assunto,
           a.nome          AS nome,
           COUNT(h.id)     AS respostas,
           SUM(h.acertou)  AS acertos,
           MAX(h.data)     AS ultimo,
           AVG(q.dificuldade) AS dificuldade
    FROM Historico_Estudo h
    JOIN Questao q ON q.id = h.id_questao
    JOIN Assunto a ON a.id = q.id_assunto
    WHERE h.id_usuario = ? ${materia == null ? '' : 'AND a.id_materia = ?'}
    GROUP BY a.id
    ORDER BY ultimo DESC
  ''',
    [usuario.id, if (materia != null) materia.id],
  );

  var respondidas = 0;
  var acertos = 0;
  final agora = DateTime.now();
  final assuntos = <SaudeAssunto>[];
  for (final l in linhas) {
    final respostas = (l['respostas'] as int?) ?? 0;
    final certas = ((l['acertos'] as num?) ?? 0).toInt();
    respondidas += respostas;
    acertos += certas;
    final ultimo = DateTime.parse(l['ultimo'] as String);
    final dias = agora.difference(ultimo).inDays;
    final complexidade = ((l['dificuldade'] as num?) ?? 1).round();
    final prob = previsor.probabilidadeLembrar(
      diasDesdeUltimoEstudo: dias,
      complexidade: complexidade,
      qtdRevisoes: respostas - 1,
    );
    // Errar puxa a retenção para baixo: pondera pela taxa de acerto.
    final retencao =
        (prob * (0.5 + 0.5 * (respostas == 0 ? 0 : certas / respostas))).clamp(
          0.0,
          1.0,
        );
    assuntos.add(
      SaudeAssunto(
        idAssunto: l['id_assunto'] as int,
        nome: l['nome'] as String,
        retencao: retencao,
        saude: previsor.classificar(retencao),
        diasDesdeUltimoEstudo: dias,
      ),
    );
  }
  assuntos.sort((a, b) => a.retencao.compareTo(b.retencao));
  return ResumoAluno(
    respondidas: respondidas,
    acertos: acertos,
    assuntos: assuntos,
  );
});
