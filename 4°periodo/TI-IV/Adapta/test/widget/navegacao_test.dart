import 'package:adapta/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navegação do protótipo: as telas existem, abrem na ordem certa e sempre há
/// como voltar.
///
/// Cada tela tem uma chave (`tela_...`) no seu Scaffold. Como as telas
/// empilhadas continuam na árvore de widgets, o teste confirma que a de cima
/// apareceu e que, ao voltar, ela saiu.
Widget app() => const ProviderScope(child: AdaptaApp());

Future<void> assentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Rola a tela até o alvo, quando ele ainda não foi construído, e toca nele.
Future<void> tocar(WidgetTester tester, Finder alvo) async {
  if (alvo.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      alvo,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await assentar(tester);
  }
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await assentar(tester);
}

Finder tela(String nome) => find.byKey(Key('tela_$nome'));

void main() {
  testWidgets('o app abre na tela inicial do aluno, sem login', (tester) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    expect(tela('inicial'), findsOneWidget);
    expect(find.byKey(const Key('botao_estudar')), findsOneWidget);
    expect(find.byKey(const Key('barra_navegacao')), findsOneWidget);
    expect(tela('auth'), findsNothing);
    expect(find.byKey(const Key('campo_senha')), findsNothing);
  });

  testWidgets('sessão de estudo: responder, ver feedback e fechar', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('botao_estudar')));
    expect(tela('sessao'), findsOneWidget);
    expect(find.byKey(const Key('alternativa_A')), findsOneWidget);

    await tocar(tester, find.byKey(const Key('alternativa_B')));
    expect(find.byKey(const Key('feedback_resposta')), findsOneWidget);
    expect(find.byKey(const Key('botao_proxima')), findsOneWidget);

    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('sessao'), findsNothing);
    expect(tela('inicial'), findsOneWidget);
  });

  testWidgets('histórico: lista, abre a resolução antiga e volta', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('aba_historico')));
    expect(tela('historico'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('item_historico_5')));
    expect(tela('resolucao'), findsOneWidget);
    expect(find.byKey(const Key('botao_refazer')), findsOneWidget);
    expect(find.textContaining('O gabarito é'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('resolucao'), findsNothing);
    expect(tela('historico'), findsOneWidget);
  });

  testWidgets('a tela inicial tem atalho para o histórico', (tester) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('atalho_historico')));
    expect(tela('historico'), findsOneWidget);
  });

  testWidgets('refazer questão a partir da resolução', (tester) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('aba_historico')));
    await tocar(tester, find.byKey(const Key('item_historico_5')));
    await tocar(tester, find.byKey(const Key('botao_refazer')));

    // A questão abre em branco, pronta para ser respondida de novo.
    expect(tela('sessao'), findsOneWidget);
    expect(find.byKey(const Key('feedback_resposta')), findsNothing);

    await tocar(tester, find.byKey(const Key('alternativa_B')));
    await tocar(tester, find.byKey(const Key('botao_proxima')));
    expect(find.text('Questão refeita'), findsOneWidget);
  });

  testWidgets('matérias: tem botão de voltar e aplica o filtro', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('chip_materia')));
    expect(tela('materias'), findsOneWidget);
    expect(find.byKey(const Key('botao_voltar')), findsOneWidget);

    // Voltar sem escolher mantém o estudo guiado.
    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('materias'), findsNothing);
    expect(find.text('Estudo guiado'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('chip_materia')));
    await tocar(tester, find.byKey(const Key('opcao_materia_2')));
    expect(tela('materias'), findsNothing);
    expect(find.text('História'), findsOneWidget);
  });

  testWidgets('perfil abre login e painel admin, ambos com volta', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('aba_perfil')));
    expect(tela('perfil'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('item_entrar')));
    expect(tela('auth'), findsOneWidget);
    expect(find.byKey(const Key('botao_entrar')), findsOneWidget);
    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('auth'), findsNothing);

    await tocar(tester, find.byKey(const Key('item_admin')));
    expect(tela('admin_menu'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('menu_admin_/admin/grafo')));
    expect(tela('admin_interna'), findsOneWidget);
    expect(find.text('Grafo de dependências'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('admin_interna'), findsNothing);
    expect(tela('admin_menu'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('botao_voltar')));
    expect(tela('admin_menu'), findsNothing);
    expect(tela('perfil'), findsOneWidget);
  });

  testWidgets('entrar pelo login troca o nome na saudação', (tester) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    await tocar(tester, find.byKey(const Key('aba_perfil')));
    await tocar(tester, find.byKey(const Key('item_entrar')));
    await tester.enterText(find.byKey(const Key('campo_email')), 'ana@x.com');
    await tester.enterText(find.byKey(const Key('campo_senha')), '123456');
    await tocar(tester, find.byKey(const Key('botao_entrar')));
    expect(tela('auth'), findsNothing);

    // A saudação da tela inicial passa a usar o nome de quem entrou.
    await tocar(tester, find.byIcon(Icons.home_outlined));
    expect(find.text('Olá, Ana'), findsOneWidget);
  });

  testWidgets('responder uma questão aumenta o contador da tela inicial', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await assentar(tester);

    final contador = find.descendant(
      of: tela('inicial'),
      matching: find.text('8'),
    );
    expect(contador, findsOneWidget); // 8 respostas de exemplo

    await tocar(tester, find.byKey(const Key('botao_estudar')));
    await tocar(tester, find.byKey(const Key('alternativa_A')));
    await tocar(tester, find.byKey(const Key('botao_voltar')));

    expect(
      find.descendant(of: tela('inicial'), matching: find.text('9')),
      findsOneWidget,
    );
  });
}
