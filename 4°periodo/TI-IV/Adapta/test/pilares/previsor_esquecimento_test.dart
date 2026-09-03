import 'package:adapta/pilares/esquecimento/previsor_esquecimento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final previsor = PrevisorExponencialFixo();

  test('retenção decai com o tempo', () {
    final hoje = previsor.probabilidadeLembrar(
      diasDesdeUltimoEstudo: 0,
      complexidade: 3,
      qtdRevisoes: 0,
    );
    final depois = previsor.probabilidadeLembrar(
      diasDesdeUltimoEstudo: 10,
      complexidade: 3,
      qtdRevisoes: 0,
    );
    expect(hoje, 1.0);
    expect(depois, lessThan(hoje));
  });

  test('revisões aumentam a retenção', () {
    final sem = previsor.probabilidadeLembrar(
      diasDesdeUltimoEstudo: 5,
      complexidade: 3,
      qtdRevisoes: 0,
    );
    final com = previsor.probabilidadeLembrar(
      diasDesdeUltimoEstudo: 5,
      complexidade: 3,
      qtdRevisoes: 4,
    );
    expect(com, greaterThan(sem));
  });

  test('classifica nas três faixas da memória', () {
    expect(previsor.classificar(0.9), SaudeMemoria.consolidado);
    expect(previsor.classificar(0.5), SaudeMemoria.emRisco);
    expect(previsor.classificar(0.1), SaudeMemoria.critico);
  });
}
