import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/firebase.dart';
import 'package:adapta/dados/repositorios/grafo_repositorio.dart';
import 'package:adapta/navegacao/rotas.dart';
import 'package:adapta/telas/aluno/mapa_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

/// Navegação do app: as telas existem, abrem na ordem certa e sempre há
/// como voltar.
///
/// Cada tela tem uma chave (`tela_...`) no seu Scaffold. Como as telas
/// empilhadas continuam na árvore de widgets, o teste confirma que a de cima
/// apareceu e que, ao voltar, ela saiu.
/// Quem está na sessão quando o app abre.
enum Quem { visitante, aluno, admin }

/// Abre o app sobre um banco em memória. O aluno já tem 8 questões respondidas.
Future<void> abrir(
  WidgetTester tester, [
  Quem quem = Quem.visitante,
  MockFirebaseAuth? auth,
  FakeFirebaseFirestore? firestore,
]) async {
  final banco = bancoDeTeste();
  await tester.runAsync(() async {
    await banco.db;
    await prepararSessao(banco, quem);
  });
  await tester.pumpWidget(
    appDeTeste(
      banco,
      overrides: [
        if (auth != null) firebaseAuthProvider.overrideWithValue(auth),
        if (firestore != null) firestoreProvider.overrideWithValue(firestore),
      ],
    ),
  );
  await assentar(tester);
}

Future<void> prepararSessao(BancoLocal banco, Quem quem) async {
  if (quem == Quem.visitante) return;
  final db = await banco.db;
  final admin = quem == Quem.admin;
  final id = await db.insert('Usuario', {
    'nome': admin ? 'Administração' : 'Ana Souza',
    'email': admin ? 'admin@adapta.app' : 'ana@x.com',
    'tipo': admin ? 'admin' : 'aluno',
  });
  if (admin) return;
  final agora = DateTime.now();
  const respostas = {
    5: 'A',
    3: 'B',
    8: 'B',
    1: 'B',
    4: 'C',
    2: 'C',
    6: 'A',
    7: 'B',
  };
  var i = 0;
  for (final MapEntry(key: questao, value: letra) in respostas.entries) {
    await db.insert('Historico_Estudo', {
      'id': 'h$questao',
      'id_usuario': id,
      'id_questao': questao,
      'letra_escolhida': letra,
      'acertou': letra == 'A' ? 0 : 1,
      'data': agora.subtract(Duration(hours: i++)).toIso8601String(),
      'tempo_gasto': 30,
      'sincronizado': 1,
      'atualizado_em': agora.toIso8601String(),
    });
  }
}

/// Dá tempo às consultas ao banco e às animações.
Future<void> assentar(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('visitante', () {
    testWidgets('o app abre na tela inicial, sem login e sem nome', (
      tester,
    ) async {
      await abrir(tester);

      expect(tela('inicial'), findsOneWidget);
      expect(tela('auth'), findsNothing);
      expect(find.text('Vamos estudar?'), findsOneWidget);
      expect(find.byKey(const Key('convite_entrar')), findsOneWidget);
      // Nenhum nome inventado na saudação.
      expect(find.textContaining('Olá,'), findsNothing);
    });

    testWidgets('estuda sem login (RF14)', (tester) async {
      await abrir(tester);

      expect(find.text('Estudar agora'), findsOneWidget);
      await tocar(tester, find.byKey(const Key('botao_estudar')));

      expect(tela('auth'), findsNothing);
      expect(tela('sessao'), findsOneWidget);
      expect(find.byKey(const Key('alternativa_A')), findsOneWidget);
    });

    testWidgets('a resposta entra no histórico mesmo sem conta', (
      tester,
    ) async {
      await abrir(tester);

      await tocar(tester, find.byKey(const Key('botao_estudar')));
      await tocar(tester, find.byKey(const Key('alternativa_A')));
      await tocar(tester, find.byKey(const Key('botao_voltar')));
      await tocar(tester, find.byKey(const Key('aba_historico')));

      expect(tela('historico'), findsOneWidget);
      expect(find.text('Você ainda não respondeu nada'), findsNothing);
    });

    testWidgets('o histórico começa vazio', (tester) async {
      await abrir(tester);

      await tocar(tester, find.byKey(const Key('aba_historico')));
      expect(tela('historico'), findsOneWidget);
      expect(find.text('Você ainda não respondeu nada'), findsOneWidget);
    });

    testWidgets('o perfil não mostra nome nem e-mail', (tester) async {
      await abrir(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      expect(find.text('Você ainda não entrou'), findsOneWidget);
      expect(find.byKey(const Key('item_entrar')), findsOneWidget);
    });

    testWidgets('entrar pelo perfil passa a usar o nome de quem entrou', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('usuarios').doc('u1').set({
        'nome': 'Ana Souza',
        'email': 'ana@x.com',
        'tipo': 'aluno',
      });
      final auth = MockFirebaseAuth();
      await abrir(tester, Quem.visitante, auth, firestore);
      auth.mockUser = MockUser(uid: 'u1', email: 'ana@x.com');

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.byKey(const Key('item_entrar')));
      await preencherLogin(tester);

      expect(tela('auth'), findsNothing);
      await tocar(tester, find.byIcon(Icons.home_outlined));
      expect(find.text('Olá, Ana'), findsOneWidget);
    });

    testWidgets('a escolha de matéria segue aberta', (tester) async {
      await abrir(tester);

      await tocar(tester, find.byKey(const Key('chip_materia')));
      expect(tela('materias'), findsOneWidget);
      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('materias'), findsNothing);
    });

    testWidgets('o perfil não revela o painel administrativo', (tester) async {
      await abrir(tester);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      expect(find.byKey(const Key('item_admin')), findsNothing);
      expect(find.text('Painel administrativo'), findsNothing);
    });
  });

  group('com aluno na sessão', () {
    testWidgets('a tela inicial saúda pelo nome e mostra o resumo', (
      tester,
    ) async {
      await abrir(tester, Quem.aluno);

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
      await abrir(tester, Quem.aluno);

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
      await abrir(tester, Quem.aluno);

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
      await abrir(tester, Quem.aluno);

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
      await abrir(tester, Quem.aluno);

      await tocar(tester, find.byKey(const Key('atalho_historico')));
      expect(tela('historico'), findsOneWidget);
    });

    testWidgets('matérias: tem botão de voltar e aplica o filtro', (
      tester,
    ) async {
      await abrir(tester, Quem.aluno);

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

    testWidgets('mapa: abre, mostra o vértice e estuda o assunto', (
      tester,
    ) async {
      await abrir(tester, Quem.aluno);

      await tocar(tester, find.byKey(const Key('atalho_mapa')));
      expect(tela('mapa'), findsOneWidget);

      final canvas = find.byKey(const Key('mapa_canvas'));
      final contexto = tester.element(canvas);
      final container = ProviderScope.containerOf(contexto);
      final grafo = await tester.runAsync(
        () => container.read(grafoProvider.future),
      );
      final area = LayoutMapa.de(grafo!).vertices[8]!;
      await tester.tapAt(tester.getTopLeft(canvas) + area.center);
      await assentar(tester);

      expect(find.byKey(const Key('detalhe_vertice')), findsOneWidget);
      expect(find.textContaining('Operações básicas'), findsWidgets);

      await tocar(tester, find.byKey(const Key('botao_estudar_assunto')));
      expect(tela('sessao'), findsOneWidget);
      expect(find.textContaining('24 latas'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('mapa'), findsNothing);
    });

    testWidgets('o aluno não vê o painel administrativo no perfil', (
      tester,
    ) async {
      await abrir(tester, Quem.aluno);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      expect(find.byKey(const Key('item_admin')), findsNothing);
      expect(find.text('Painel administrativo'), findsNothing);
    });

    testWidgets('a rota do painel não abre para o aluno', (tester) async {
      await abrir(tester, Quem.aluno);

      final contexto = tester.element(find.byType(MaterialApp));
      ProviderScope.containerOf(contexto).read(routerProvider).go('/admin');
      await assentar(tester);

      expect(tela('admin_menu'), findsNothing);
      expect(tela('inicial'), findsOneWidget);
    });

    testWidgets('responder uma questão aumenta o contador da tela inicial', (
      tester,
    ) async {
      await abrir(tester, Quem.aluno);

      await tocar(tester, find.byKey(const Key('botao_estudar')));
      await tocar(tester, find.byKey(const Key('alternativa_A')));
      await tocar(tester, find.byKey(const Key('botao_voltar')));

      expect(
        find.descendant(of: tela('inicial'), matching: find.text('9')),
        findsOneWidget,
      );
    });

    testWidgets('sair da conta devolve a tela inicial neutra', (tester) async {
      await abrir(tester, Quem.aluno);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.text('Sair da conta'));

      await tocar(tester, find.byIcon(Icons.home_outlined));
      expect(find.text('Vamos estudar?'), findsOneWidget);
      expect(find.text('Olá, Ana'), findsNothing);
    });
  });

  group('com administrador na sessão', () {
    testWidgets('aresta que fecharia ciclo é recusada e não é gravada', (
      tester,
    ) async {
      await abrir(tester, Quem.admin);
      final contexto = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(contexto);
      container.read(routerProvider).go('/admin/grafo');
      await assentar(tester);
      await assentar(tester);

      // Logaritmo → Potenciação: Potenciação já é pré-requisito de Logaritmo.
      await tocar(tester, find.text('Nova aresta'));
      await tester.tap(find.widgetWithText(InputDecorator, 'Pré-requisito'));
      await assentar(tester);
      await tester.tap(find.text('Logaritmo').last);
      await assentar(tester);
      await tester.tap(find.widgetWithText(InputDecorator, 'Dependente'));
      await assentar(tester);
      await tester.tap(find.text('Potenciação').last);
      await assentar(tester);
      await tester.tap(find.text('Salvar'));
      await assentar(tester);

      expect(find.textContaining('fecharia um ciclo'), findsOneWidget);
      final arestas = await tester.runAsync(
        () => container.read(grafoRepositorioProvider).listar(),
      );
      expect(arestas!.any((d) => d.prerequisito == 5), isFalse);
    });

    testWidgets('o painel aparece no perfil e abre', (tester) async {
      await abrir(tester, Quem.admin);

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      expect(find.byKey(const Key('item_admin')), findsOneWidget);

      await tocar(tester, find.byKey(const Key('item_admin')));
      expect(tela('admin_menu'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('menu_admin_/admin/grafo')));
      expect(tela('admin_interna'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('admin_interna'), findsNothing);
      await tocar(tester, find.byKey(const Key('botao_voltar')));
      expect(tela('perfil'), findsOneWidget);
    });

    testWidgets('conta com tipo admin no Firestore dá acesso ao painel', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('usuarios').doc('adm').set({
        'nome': 'Administração',
        'email': 'admin@adapta.app',
        'tipo': 'admin',
      });
      final auth = MockFirebaseAuth();
      await abrir(tester, Quem.visitante, auth, firestore);
      auth.mockUser = MockUser(uid: 'adm', email: 'admin@adapta.app');

      await tocar(tester, find.byKey(const Key('aba_perfil')));
      await tocar(tester, find.byKey(const Key('item_entrar')));
      await tester.enterText(
        find.byKey(const Key('campo_email')),
        'admin@adapta.app',
      );
      await tester.enterText(find.byKey(const Key('campo_senha')), '123456');
      await tocar(tester, find.byKey(const Key('botao_entrar')));

      expect(find.byKey(const Key('item_admin')), findsOneWidget);
    });
  });
}
