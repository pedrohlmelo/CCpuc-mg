import 'dart:math';

/// Regressão logística treinada em `ia/treinar.py`. Os coeficientes vêm de
/// `assets/modelos/esquecimento.json`.
class ModeloEsquecimento {
  final double intercepto;
  final double log1pDias;
  final double qtdRevisoes;
  final double dificuldade;
  final double taxaAcerto;

  const ModeloEsquecimento({
    required this.intercepto,
    required this.log1pDias,
    required this.qtdRevisoes,
    required this.dificuldade,
    required this.taxaAcerto,
  });

  factory ModeloEsquecimento.deJson(Map<String, dynamic> json) {
    final c = json['coeficientes'] as Map<String, dynamic>;
    double coeficiente(String nome) => (c[nome] as num).toDouble();
    return ModeloEsquecimento(
      intercepto: (json['intercepto'] as num).toDouble(),
      log1pDias: coeficiente('log1p_dias'),
      qtdRevisoes: coeficiente('qtd_revisoes'),
      dificuldade: coeficiente('dificuldade'),
      taxaAcerto: coeficiente('taxa_acerto_aluno'),
    );
  }

  double probabilidadeLembrar({
    required double dias,
    required int qtdRevisoes,
    required double dificuldade,
    required double taxaAcerto,
  }) {
    final z =
        intercepto +
        log1pDias * log(1 + dias) +
        this.qtdRevisoes * qtdRevisoes +
        this.dificuldade * dificuldade +
        this.taxaAcerto * taxaAcerto;
    return 1 / (1 + exp(-z));
  }
}
