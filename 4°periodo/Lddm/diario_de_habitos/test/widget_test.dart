import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:diario_de_habitos/habitos_store.dart';
import 'package:diario_de_habitos/main.dart';

void main() {
  testWidgets('novo hábito aparece na lista e no resumo', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(),
        child: const DiarioApp(),
      ),
    );

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
}
