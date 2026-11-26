import 'montador_fila.dart';

/// A fila e a memória do aluno num instante da simulação.
class MomentoFila {
  /// Dias a partir de hoje (0 = hoje).
  final int dias;
  final Map<int, double> retencoes;
  final List<ItemFila> itens;
  const MomentoFila({
    required this.dias,
    required this.retencoes,
    required this.itens,
  });

  Map<int, int> get porAssunto {
    final contagem = <int, int>{};
    for (final i in itens) {
      contagem[i.questao.idAssunto] = (contagem[i.questao.idAssunto] ?? 0) + 1;
    }
    return contagem;
  }
}

/// Uma mudança de um assunto entre as duas filas.
class MudancaFila {
  final int idAssunto;
  final String assunto;

  /// Quantas questões do assunto entram (positivo) ou saem (negativo).
  final int diferenca;

  /// Motivo das questões que entraram, quando entraram.
  final MotivoFila? motivo;

  /// O assunto saiu porque depende do pré-requisito que ficou crítico.
  final bool bloqueado;

  const MudancaFila({
    required this.idAssunto,
    required this.assunto,
    required this.diferenca,
    this.motivo,
    this.bloqueado = false,
  });
}

/// "O que muda na fila do dia quando um pré-requisito fica crítico": a fila de
/// hoje e a de quando o modelo prevê que o pré-requisito cai para o vermelho,
/// sem o aluno estudar até lá. É só cálculo; nada é gravado.
class SimulacaoFila {
  final int idPrerequisito;

  /// Matéria das duas filas.
  final String? materia;
  final Map<int, String> nomes;

  /// Assuntos que dependem do pré-requisito, no grafo.
  final List<int> dependentes;
  final MomentoFila antes;
  final MomentoFila depois;

  const SimulacaoFila({
    required this.idPrerequisito,
    required this.materia,
    required this.nomes,
    required this.dependentes,
    required this.antes,
    required this.depois,
  });

  String nome(int id) => nomes[id] ?? 'Assunto #$id';

  String get prerequisito => nome(idPrerequisito);

  double get retencaoAntes => antes.retencoes[idPrerequisito] ?? 0;
  double get retencaoDepois => depois.retencoes[idPrerequisito] ?? 0;

  /// Primeiro o que saiu, depois o que entrou; dentro de cada grupo, a maior
  /// diferença primeiro.
  List<MudancaFila> get mudancas {
    final a = antes.porAssunto;
    final d = depois.porAssunto;
    final saida = <MudancaFila>[];
    for (final id in {...a.keys, ...d.keys}) {
      final diferenca = (d[id] ?? 0) - (a[id] ?? 0);
      if (diferenca == 0) continue;
      saida.add(
        MudancaFila(
          idAssunto: id,
          assunto: nome(id),
          diferenca: diferenca,
          motivo: diferenca > 0
              ? depois.itens.firstWhere((i) => i.questao.idAssunto == id).motivo
              : null,
          bloqueado: diferenca < 0 && dependentes.contains(id),
        ),
      );
    }
    saida.sort((x, y) {
      final grupo = (x.diferenca > 0 ? 1 : 0).compareTo(
        y.diferenca > 0 ? 1 : 0,
      );
      if (grupo != 0) return grupo;
      return y.diferenca.abs().compareTo(x.diferenca.abs());
    });
    return saida;
  }
}
