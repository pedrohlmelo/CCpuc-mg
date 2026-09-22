@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:adapta/app.dart';
import 'package:adapta/navegacao/rotas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gera capturas de tela em PNG (390×844 @2x) para revisão visual e slides.
///
/// Não roda no `flutter test` padrão. Para gerar:
///   CAPTURAS=1 flutter test test/capturas --tags capturas
/// Saída: `capturas/` na raiz do projeto (ou `CAPTURAS_DIR`).
void main() {
  final ativo = Platform.environment['CAPTURAS'] == '1';
  final dir = Directory(Platform.environment['CAPTURAS_DIR'] ?? 'capturas');
  final chaveRaiz = GlobalKey();

  setUpAll(() async {
    if (!ativo) return;
    dir.createSync(recursive: true);
    final fonte = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fontes/PlusJakartaSans.ttf'));
    await fonte.load();
    final icones = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icones.load();
  });

  Widget app() => RepaintBoundary(
    key: chaveRaiz,
    child: const ProviderScope(child: AdaptaApp()),
  );

  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> precarregarImagens(WidgetTester tester) async {
    final contexto = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      for (final pose in ['normal', 'feliz', 'pensativo']) {
        await precacheImage(
          AssetImage('assets/mascote/camu_$pose.png'),
          contexto,
        );
      }
    });
    await tester.pump();
  }

  Future<void> capturar(WidgetTester tester, String nome) async {
    await assentar(tester);
    final boundary =
        chaveRaiz.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagem = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
    final bytes = await tester.runAsync(
      () => imagem!.toByteData(format: ui.ImageByteFormat.png),
    );
    File('${dir.path}/$nome.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  void ir(WidgetTester tester, String rota) {
    final contexto = tester.element(find.byType(MaterialApp));
    ProviderScope.containerOf(contexto).read(routerProvider).go(rota);
  }

  Future<void> iniciar(WidgetTester tester, {bool escuro = false}) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.platformBrightnessTestValue = escuro
        ? Brightness.dark
        : Brightness.light;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(app());
    await assentar(tester);
    await precarregarImagens(tester);
  }

  testWidgets('telas do aluno', (tester) async {
    await iniciar(tester);
    await capturar(tester, '01_inicial_aluno');

    ir(tester, '/historico');
    await capturar(tester, '02_historico');

    ir(tester, '/historico/5');
    await capturar(tester, '03_historico_resolucao');

    ir(tester, '/sessao');
    await capturar(tester, '04_questao');

    await tester.tap(find.byKey(const Key('alternativa_B')));
    await capturar(tester, '05_questao_feedback');

    ir(tester, '/materias');
    await capturar(tester, '06_materias');

    ir(tester, '/perfil');
    await capturar(tester, '07_perfil');
  }, skip: !ativo);

  testWidgets('telas de conta', (tester) async {
    await iniciar(tester);
    ir(tester, '/login');
    await capturar(tester, '08_login');

    ir(tester, '/cadastro');
    await capturar(tester, '09_cadastro');
  }, skip: !ativo);

  testWidgets('painel administrativo', (tester) async {
    await iniciar(tester);
    ir(tester, '/admin');
    await capturar(tester, '10_admin_inicial');

    ir(tester, '/admin/grafo');
    await capturar(tester, '11_admin_grafo');

    ir(tester, '/admin/questoes');
    await capturar(tester, '12_admin_questoes');

    ir(tester, '/admin/assuntos');
    await capturar(tester, '13_admin_assuntos');

    ir(tester, '/admin/materias');
    await capturar(tester, '14_admin_materias');
  }, skip: !ativo);

  testWidgets('tema escuro', (tester) async {
    await iniciar(tester, escuro: true);
    await capturar(tester, '15_inicial_escuro');

    ir(tester, '/historico');
    await capturar(tester, '16_historico_escuro');

    ir(tester, '/admin');
    await capturar(tester, '17_admin_escuro');
  }, skip: !ativo);
}
