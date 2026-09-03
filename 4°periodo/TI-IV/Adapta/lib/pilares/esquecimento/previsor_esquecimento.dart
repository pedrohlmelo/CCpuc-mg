import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de um assunto para o aluno, conforme seção 4 da memória.
enum SaudeMemoria { consolidado, emRisco, critico, naoEstudado }

/// Pilar 2 — contrato do previsor da curva de esquecimento (RF07, RF08).
///
/// Entrada: `dias_desde_ultimo_estudo`, `complexidade`, `qtd_revisoes`.
/// Saída: probabilidade de o aluno **lembrar** (0.0 .. 1.0).
abstract class PrevisorEsquecimento {
  double probabilidadeLembrar({
    required int diasDesdeUltimoEstudo,
    required int complexidade,
    required int qtdRevisoes,
  });

  SaudeMemoria classificar(double probabilidade) {
    if (probabilidade >= 0.7) return SaudeMemoria.consolidado;
    if (probabilidade >= 0.4) return SaudeMemoria.emRisco;
    return SaudeMemoria.critico;
  }
}

/// Implementação provisória: decaimento exponencial fixo (estilo Ebbinghaus),
/// igual para todo aluno. Será substituída pelo modelo que aprende o ritmo
/// individual de esquecimento.
class PrevisorExponencialFixo extends PrevisorEsquecimento {
  @override
  double probabilidadeLembrar({
    required int diasDesdeUltimoEstudo,
    required int complexidade,
    required int qtdRevisoes,
  }) {
    // Estabilidade em dias: cresce com revisões, cai com complexidade.
    final estabilidade =
        6.0 *
        (1 + 0.8 * qtdRevisoes.clamp(0, 50)) /
        (0.6 + 0.2 * complexidade.clamp(1, 5));
    return math.exp(-diasDesdeUltimoEstudo / estabilidade);
  }
}

final previsorEsquecimentoProvider = Provider<PrevisorEsquecimento>(
  (_) => PrevisorExponencialFixo(),
);
