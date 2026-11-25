import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Reconhece o gesto de balançar o celular a partir da aceleração do usuário,
/// já sem a gravidade (m/s²).
///
/// Um balanço são [picosNecessarios] picos acima de [limiar] dentro de
/// [janela]. Um pico só conta quando a aceleração volta para baixo do limiar
/// e sobe de novo, porque uma sacudida gera várias leituras altas seguidas.
/// Depois de um balanço, o detector fica [pausa] sem disparar, para um mesmo
/// gesto não abrir duas questões.
class DetectorBalanco {
  final double limiar;
  final int picosNecessarios;
  final Duration janela;
  final Duration pausa;

  DetectorBalanco({
    this.limiar = 13,
    this.picosNecessarios = 2,
    this.janela = const Duration(milliseconds: 1000),
    this.pausa = const Duration(seconds: 3),
  });

  final _picos = <DateTime>[];
  bool _acima = false;
  DateTime? _ultimoBalanco;

  /// Registra uma leitura e diz se ela completou um balanço.
  bool registrar(double x, double y, double z, DateTime quando) {
    final forca = sqrt(x * x + y * y + z * z);
    final subiu = forca >= limiar && !_acima;
    _acima = forca >= limiar;
    if (!subiu) return false;

    final ultimo = _ultimoBalanco;
    if (ultimo != null && quando.difference(ultimo) < pausa) return false;

    _picos
      ..add(quando)
      ..removeWhere((p) => quando.difference(p) > janela);
    if (_picos.length < picosNecessarios) return false;

    _picos.clear();
    _ultimoBalanco = quando;
    return true;
  }
}

/// Leitura do acelerômetro: (x, y, z) sem a gravidade.
typedef Aceleracao = ({double x, double y, double z});

/// Leituras do acelerômetro. Nos testes, e em aparelhos sem o sensor, o erro
/// do plugin é engolido e o gesto simplesmente não acontece.
final aceleracaoProvider = Provider<Stream<Aceleracao>>(
  (_) => userAccelerometerEventStream(
    samplingPeriod: SensorInterval.uiInterval,
  ).map<Aceleracao>((e) => (x: e.x, y: e.y, z: e.z)).handleError((Object _) {}),
);

/// Um evento a cada balanço reconhecido.
final balancoProvider = Provider<Stream<void>>((ref) {
  final detector = DetectorBalanco();
  return ref
      .watch(aceleracaoProvider)
      .where((a) => detector.registrar(a.x, a.y, a.z, DateTime.now()));
});
