import 'dart:math';

/// Rasch: P(acerto) = sigmoide(θ − b). O θ é do aluno em cada assunto e o `b`
/// é da questão, vindo de `assets/modelos/dificuldades.json`.
class ModeloProficiencia {
  static const taxaTheta = 0.4;
  static const taxaDificuldade = 0.05;

  final Map<int, double> dificuldades;
  const ModeloProficiencia(this.dificuldades);

  factory ModeloProficiencia.deJson(Map<String, dynamic> json) =>
      ModeloProficiencia({
        for (final e in json.entries)
          int.parse(e.key): (e.value as num).toDouble(),
      });

  static double probabilidadeAcerto(double theta, double b) =>
      1 / (1 + exp(-(theta - b)));

  /// Passo depois de uma resposta: devolve os novos θ e b.
  static ({double theta, double b}) atualizar(
    double theta,
    double b,
    bool acertou,
  ) {
    final erro = (acertou ? 1.0 : 0.0) - probabilidadeAcerto(theta, b);
    return (theta: theta + taxaTheta * erro, b: b - taxaDificuldade * erro);
  }
}
