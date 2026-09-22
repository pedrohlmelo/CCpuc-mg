import 'package:adapta/app.dart';
import 'package:adapta/tema/tema_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('botão sol/lua alterna o tema', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [temaInicialProvider.overrideWithValue(ThemeMode.light)],
        child: const AdaptaApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final botao = find.byKey(const Key('botao_tema'));
    expect(botao, findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(Theme.of(tester.element(botao)).brightness, Brightness.light);

    await tester.tap(botao);
    // 1º frame aplica o novo themeMode; 2º conclui a animação do tema.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(Theme.of(tester.element(botao)).brightness, Brightness.dark);

    await tester.tap(botao);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(Theme.of(tester.element(botao)).brightness, Brightness.light);
  });
}
