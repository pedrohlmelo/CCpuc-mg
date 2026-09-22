import 'package:adapta/app.dart';
import 'package:adapta/dados/estado_prototipo.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Navegação do protótipo: as telas existem, abrem na ordem certa e sempre há
/// como voltar.
///
/// Cada tela tem uma chave (`tela_...`) no seu Scaffold. Como as telas
/// empilhadas continuam na árvore de widgets, o teste confirma que a de cima
/// apareceu e que, ao voltar, ela saiu.
Widget app({Aluno? aluno}) => ProviderScope(
  overrides: [
    if (aluno != null) alunoProvider.overrideWith((_) => aluno),
  ],
  child: const AdaptaApp(),
);

const alunoDeTeste = Aluno(nome: 'Ana Souza', email: 'ana@x.com');

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

Future<void> preencherLogin(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('campo_email')), 'ana@x.com');
  await tester.enterText(find.byKey(const Key('campo_senha')), '123456');
  await tocar(tester, find.byKey(const Key('botao_entrar')));
}

Finder tela(String nome) => find.byKey(Key('tela_$nome'));

void main() {
  group('sem ninguém na sessão', () {
    testWidgets('o app abre na tela inicial, sem login e sem nome', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      expect(tela('inicial'), findsOneWidget);
      expect(tela('auth'), findsNothing);
      expect(find.text('Vamos estudar?'), findsOneWidget);
      expect(find.byKey(const Key('convite_entrar')), findsOneWidget);
      // Nenhum nome inventado na saudação.
      expect(find.textContaining('Olá,'), findsNothing);
    });

    testWidgets('estudar leva ao login antes da questão', (tester) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      expect(find.text('Entrar para estudar'), findsOneWidget);
      await tocar(tester, find.byKey(const Key('botao_estudar')));

      expect(tela('auth'), findsOneWidget);
      expect(tela('sessao'), findsNothing);
      expect(find.byKey(const Key('alternativa_A')), findsNothing);
    });

    testWidgets('ao entrar, segue direto para a questão', (tester) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('botao_estudar')));
      await preencherLogin(tester);

      expect(tela('sessao'), findsOneWidget);
      expect(find.byKey(const Key('alternativa_A')), findsOneWidget);
    });

    testWidgets('o histórico pede para entrar em vez de mostrar dados', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_historico')));
      expect(tela('historico'), findsOneWidget);
      expect(find.byKey(const Key('botao_entrar_historico')), findsOneWidget);
      expect(find.byKey(const Key('item_historico_5')), findsNothing);
    });

    testWidgets('o perfil não mostra nome nem e-mail', (tester) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      expect(find.text('Você ainda não entrou'), findsOneWidget);
      expect(find.byKey(const Key('item_entrar')), findsOneWidget);
    });

    testWidgets('entrar pelo perfil passa a usar o nome de quem entrou', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.byKey(const Key('item_entrar')));
      await preencherLogin(tester);

      expect(tela('auth'), findsNothing);
      await tocar(tester, find.byIcon(Icons.home_outlined));
      expect(find.text('Olá, Ana'), findsOneWidget);
    });

    testWidgets('matérias e painel administrativo seguem abertos', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('chip_materia')));
      expect(tela('materias'), findsOneWidget);
      await tocar(tester, find.byKey(const Key('botao_voltar')));

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.byKey(const Key('item_admin')));
      expect(tela('admin_menu'), findsOneWidget);
    });
  });

  group('com aluno na sessão', () {
    testWidgets('a tela inicial saúda pelo nome e mostra o resumo', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      expect(find.text('Olá, Ana'), findsOneWidget);
      expect(find.byKey(const Key('convite_entrar')), findsNothing);
      expect(
        find.descendant(of: tela('inicial'), matching: find.text('8')),
        findsOneWidget,
      );
    });

    testWidgets('sessão de estudo: responder, ver feedback e fechar', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('botao_estudar')));
      expect(tela('sessao'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('alternativa_B')));
      expect(find.byKey(const Key('feedback_resposta')), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('sessao'), findsNothing);
      expect(tela('inicial'), findsOneWidget);
    });

    testWidgets('histórico: lista, abre a resolução antiga e volta', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_historico')));
      await tocar(tester, find.byKey(const Key('item_historico_5')));

      expect(tela('resolucao'), findsOneWidget);
      expect(find.byKey(const Key('botao_refazer')), findsOneWidget);
      expect(find.textContaining('O gabarito é'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('resolucao'), findsNothing);
      expect(tela('historico'), findsOneWidget);
    });

    testWidgets('refazer questão a partir da resolução', (tester) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_historico')));
      await tocar(tester, find.byKey(const Key('item_historico_5')));
      await tocar(tester, find.byKey(const Key('botao_refazer')));

      expect(tela('sessao'), findsOneWidget);
      expect(find.byKey(const Key('feedback_resposta')), findsNothing);

      await tocar(tester, find.byKey(const Key('alternativa_B')));
      await tocar(tester, find.byKey(const Key('botao_proxima')));
      expect(find.text('Questão refeita'), findsOneWidget);
    });

    testWidgets('a tela inicial tem atalho para o histórico', (tester) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('atalho_historico')));
      expect(tela('historico'), findsOneWidget);
    });

    testWidgets('matérias: tem botão de voltar e aplica o filtro', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('chip_materia')));
      expect(tela('materias'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('materias'), findsNothing);
      expect(find.text('Estudo guiado'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('chip_materia')));
      await tocar(tester, find.byKey(const Key('opcao_materia_2')));
      expect(tela('materias'), findsNothing);
      expect(find.text('História'), findsOneWidget);
    });

    testWidgets('painel administrativo abre e volta pelo perfil', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.byKey(const Key('item_admin')));
      expect(tela('admin_menu'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('menu_admin_/admin/grafo')));
      expect(tela('admin_interna'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('admin_interna'), findsNothing);
      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('perfil'), findsOneWidget);
    });

    testWidgets('responder uma questão aumenta o contador da tela inicial', (
      tester,
    ) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('botao_estudar')));
      await tocar(tester, find.byKey(const Key('alternativa_A')));
      await tocar(tester, find.byKey(const Key('botao_voltar')));

      expect(
        find.descendant(of: tela('inicial'), matching: find.text('9')),
        findsOneWidget,
      );
    });

    testWidgets('sair da conta devolve a tela inicial neutra', (tester) async {
      await tester.pumpWidget(app(aluno: alunoDeTeste));
      await assentar(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.text('Sair da conta'));

      await tocar(tester, find.byIcon(Icons.home_outlined));
      expect(find.text('Vamos estudar?'), findsOneWidget);
      expect(find.text('Olá, Ana'), findsNothing);
    });
  });
}
