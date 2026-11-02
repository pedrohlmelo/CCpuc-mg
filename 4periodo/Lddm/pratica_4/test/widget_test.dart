import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pratica_9/dados/habitos_repositorio.dart';
import 'package:pratica_9/dados/preferencias.dart';
import 'package:pratica_9/dominio/habito.dart';
import 'package:pratica_9/dominio/habitos_store.dart';
import 'package:pratica_9/main.dart';

// O sqflite não roda no flutter test: aqui o repositório guarda em memória.
class RepositorioEmMemoria extends HabitosRepositorio {
  int _proximoId = 1;
  late final List<Habito> _memoria = [
    _novo('Beber água', 'Meta: 8 copos por dia', 'agua'),
    _novo('Ler', 'Meta: 20 páginas por dia', 'leitura'),
    _novo('Caminhar', 'Meta: 30 minutos por dia', 'caminhada'),
    _novo('Dormir cedo', 'Meta: antes das 23h', 'sono'),
  ];

  Habito _novo(String nome, String meta, String icone) =>
      Habito(id: _proximoId++, nome: nome, meta: meta, icone: icone);

  @override
  Future<List<Habito>> carregar() async => List.of(_memoria);

  @override
  Future<void> salvar(Habito h) async =>
      _memoria.add(_novo(h.nome, h.meta, h.icone));

  @override
  Future<void> atualizar(Habito h) async {
    final i = _memoria.indexWhere((x) => x.id == h.id);
    if (i >= 0) _memoria[i] = h;
  }

  @override
  Future<void> apagar(int id) async => _memoria.removeWhere((x) => x.id == id);

  @override
  Future<void> arquivar(Habito h) async {
    await apagar(h.id!);
    await salvar(h);
  }
}

void main() {
  testWidgets('novo hábito aparece na lista e no resumo', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(RepositorioEmMemoria())..carregar(),
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
        create: (_) => HabitosStore(RepositorioEmMemoria())..carregar(),
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

  testWidgets('hábito arquivado vai para o fim da lista', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(RepositorioEmMemoria())..carregar(),
        child: const DiarioApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beber água'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();

    final nomes = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();

    expect(nomes, ['Ler', 'Caminhar', 'Dormir cedo', 'Beber água']);

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();

    expect(find.text('4 hábitos'), findsOneWidget);
  });

  testWidgets('tema escolhido fica salvo no shared_preferences', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HabitosStore(RepositorioEmMemoria())..carregar(),
        child: const DiarioApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tema escuro'));
    await tester.pumpAndSettle();

    expect(await lerTema(), isTrue);
  });
}
