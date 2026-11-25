import 'dart:async';

import 'package:adapta/sensores/detector_balanco.dart';
import 'package:adapta/widgets/cartoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

/// Balançar o celular abre a questão relâmpago, escolhida pela fila adaptativa.
void main() {
  late StreamController<Aceleracao> sensor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sensor = StreamController<Aceleracao>.broadcast();
  });
  tearDown(() => sensor.close());

  Future<void> assentar(WidgetTester tester) async {
    for (
      var i = 0;
      i < 6 || (i < 60 && find.byType(Carregando).evaluate().isNotEmpty);
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    rootBundle.clear();
    final banco = bancoDeTeste();
    await tester.runAsync(() async => banco.db);
    await tester.pumpWidget(
      appDeTeste(
        banco,
        overrides: [aceleracaoProvider.overrideWithValue(sensor.stream)],
      ),
    );
    await assentar(tester);
  }

  /// Dois trancos fortes, com uma parada no meio.
  Future<void> balancar(WidgetTester tester) async {
    for (final forca in [20.0, 0.0, 20.0]) {
      sensor.add((x: forca, y: 0, z: 0));
      await tester.pump();
    }
    // Montar a fila passa por vários passos no banco.
    for (
      var i = 0;
      i < 20 && find.byKey(const Key('painel_relampago')).evaluate().isEmpty;
      i++
    ) {
      await assentar(tester);
    }
  }

  testWidgets('balançar nas abas abre a questão relâmpago', (tester) async {
    await abrir(tester);
    expect(find.byKey(const Key('painel_relampago')), findsNothing);

    await balancar(tester);

    expect(find.byKey(const Key('painel_relampago')), findsOneWidget);
    expect(find.text('Questão relâmpago'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_responder_relampago')));
    await assentar(tester);
    expect(find.byKey(const Key('tela_sessao')), findsOneWidget);
    expect(find.byKey(const Key('painel_relampago')), findsNothing);
  });

  testWidgets('durante a sessão o gesto é ignorado', (tester) async {
    await abrir(tester);
    await tester.tap(find.byKey(const Key('botao_estudar')));
    await assentar(tester);
    expect(find.byKey(const Key('tela_sessao')), findsOneWidget);

    await balancar(tester);

    expect(find.byKey(const Key('painel_relampago')), findsNothing);
  });
}
