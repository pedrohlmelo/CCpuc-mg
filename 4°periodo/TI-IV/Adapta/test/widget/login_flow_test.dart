import 'package:adapta/app.dart';
import 'package:adapta/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_helpers.dart';

/// O banco roda em thread real; o teste de widget roda em tempo falso.
/// [esperar] deixa o I/O real terminar e depois repinta a árvore.
Future<void> esperar(WidgetTester tester) async {
  // Várias rodadas: um build pode disparar nova consulta ao banco.
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  late Database db;

  setUp(() async => db = await bancoDeTeste());
  tearDown(() => db.close());

  Widget app() => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const AdaptaApp(),
  );

  Future<void> login(WidgetTester tester, String email, String senha) async {
    await tester.enterText(find.byKey(const Key('campo_email')), email);
    await tester.enterText(find.byKey(const Key('campo_senha')), senha);
    await tester.tap(find.byKey(const Key('botao_entrar')));
    await esperar(tester);
  }

  testWidgets('login inválido mostra erro', (tester) async {
    await tester.pumpWidget(app());
    await esperar(tester);

    await login(tester, 'x@x.com', 'errada');

    expect(find.byKey(const Key('erro_login')), findsOneWidget);
  });

  testWidgets('admin entra e cai no painel administrativo (RF01, RF11)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await esperar(tester);

    await login(tester, 'admin@adapta.app', 'admin123');

    expect(find.text('Painel administrativo'), findsOneWidget);
  });

  testWidgets('aluno: cadastro → matéria → home → questão (RF01, RF02, RF04)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await esperar(tester);

    await tester.tap(find.text('Criar conta'));
    await esperar(tester);
    await tester.enterText(find.byKey(const Key('campo_nome')), 'Ana');
    await tester.enterText(find.byKey(const Key('campo_email')), 'ana@x.com');
    await tester.enterText(find.byKey(const Key('campo_senha')), '123456');
    await tester.tap(find.byKey(const Key('botao_cadastrar')));
    await esperar(tester);

    expect(find.byKey(const Key('opcao_estudo_geral')), findsOneWidget);
    await tester.tap(find.byKey(const Key('opcao_estudo_geral')));
    await esperar(tester);

    await tester.tap(find.byKey(const Key('botao_estudar')));
    await esperar(tester);

    expect(find.byKey(const Key('alternativa_A')), findsOneWidget);
    await tester.tap(find.byKey(const Key('alternativa_B')));
    await esperar(tester);

    expect(find.byKey(const Key('feedback_resposta')), findsOneWidget);
    expect(find.byKey(const Key('botao_proxima')), findsOneWidget);

    final registros = await tester.runAsync(() => db.query('Historico_Estudo'));
    expect(registros!.length, 1);
  });
}
