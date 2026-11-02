import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:diario_de_habitos_2/dados/habitos_repositorio.dart';
import 'package:diario_de_habitos_2/dominio/habitos_store.dart';
import 'package:diario_de_habitos_2/main.dart';

void main() {
  testWidgets('novo hábito aparece na lista e no resumo', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(HabitosRepositorio())..carregar(),
        child: const DiarioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beber água'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Meditar');
    await tester.enterText(find.byType(TextFormField).at(1), 'Meta: 10 minutos');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Meditar'), findsOneWidget);

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();

    expect(find.text('5 hábitos'), findsOneWidget);
  });

  testWidgets('hábito removido some da lista e do resumo', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(HabitosRepositorio())..carregar(),
        child: const DiarioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ler'), findsOneWidget);

    await tester.tap(find.text('Ler'));
    await tester.pumpAndSettle();

    expect(find.text('Meta: 20 páginas por dia'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Ler'), findsNothing);

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();

    expect(find.text('3 hábitos'), findsOneWidget);
  });
}
