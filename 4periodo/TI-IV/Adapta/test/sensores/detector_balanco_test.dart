import 'package:adapta/sensores/detector_balanco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final inicio = DateTime(2026, 11, 25, 10);
  DateTime em(int ms) => inicio.add(Duration(milliseconds: ms));

  /// Uma leitura forte (pico) ou parada, no eixo x.
  bool ler(DetectorBalanco d, int ms, {bool forte = true}) =>
      d.registrar(forte ? 20 : 0, 0, 0, em(ms));

  test('dois picos dentro de 1 s são um balanço', () {
    final d = DetectorBalanco();
    expect(ler(d, 0), isFalse);
    expect(ler(d, 100, forte: false), isFalse);
    expect(ler(d, 300), isTrue);
  });

  test('leituras altas seguidas contam como um pico só', () {
    final d = DetectorBalanco();
    expect(ler(d, 0), isFalse);
    expect(ler(d, 50), isFalse);
    expect(ler(d, 100), isFalse);
  });

  test('picos longe demais um do outro não disparam', () {
    final d = DetectorBalanco();
    ler(d, 0);
    ler(d, 100, forte: false);
    expect(ler(d, 1500), isFalse);
  });

  test('movimento leve não conta', () {
    final d = DetectorBalanco();
    for (var ms = 0; ms < 1000; ms += 100) {
      expect(d.registrar(5, 5, 5, em(ms)), isFalse);
    }
  });

  test('depois de um balanço, espera a pausa antes do próximo', () {
    final d = DetectorBalanco();
    ler(d, 0);
    ler(d, 100, forte: false);
    expect(ler(d, 200), isTrue);

    ler(d, 300, forte: false);
    ler(d, 400);
    ler(d, 500, forte: false);
    expect(ler(d, 600), isFalse);

    ler(d, 3300, forte: false);
    ler(d, 3400);
    ler(d, 3500, forte: false);
    expect(ler(d, 3600), isTrue);
  });
}
