/// Evento de resposta. É a linha `[id_usuario, id_questao, acertou]` que
/// alimenta o Pilar 1 e, agregada por assunto, o Pilar 2.
class HistoricoEstudo {
  final int id;
  final int idUsuario;
  final int idQuestao;
  final bool acertou;
  final DateTime data;
  final int tempoGastoSegundos;

  const HistoricoEstudo({
    required this.id,
    required this.idUsuario,
    required this.idQuestao,
    required this.acertou,
    required this.data,
    this.tempoGastoSegundos = 0,
  });

  factory HistoricoEstudo.deMapa(Map<String, Object?> m) => HistoricoEstudo(
    id: m['id'] as int,
    idUsuario: m['id_usuario'] as int,
    idQuestao: m['id_questao'] as int,
    acertou: (m['acertou'] as int) == 1,
    data: DateTime.parse(m['data'] as String),
    tempoGastoSegundos: m['tempo_gasto'] as int,
  );
}
