import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dados/estado_prototipo.dart';
import '../dados/modelos.dart';
import '../telas/admin/admin_assuntos_screen.dart';
import '../telas/admin/admin_grafo_screen.dart';
import '../telas/admin/admin_home_screen.dart';
import '../telas/admin/admin_materias_screen.dart';
import '../telas/admin/admin_questoes_screen.dart';
import '../telas/aluno/historico_detalhe_screen.dart';
import '../telas/aluno/historico_screen.dart';
import '../telas/aluno/home_screen.dart';
import '../telas/aluno/materias_screen.dart';
import '../telas/aluno/perfil_screen.dart';
import '../telas/aluno/sessao_screen.dart';
import '../telas/auth/cadastro_screen.dart';
import '../telas/auth/login_screen.dart';
import 'casca_aluno.dart';

/// Mapa de navegação do app.
///
/// O app abre em `/`, a tela inicial do aluno: não há tela de login na
/// abertura. A tela inicial se apresenta sem nome e, para estudar, manda
/// entrar: quem chega em `/sessao` sem ter entrado é levado ao login e volta
/// para a sessão depois.
///
/// O painel administrativo é de uso interno do grupo. As rotas `/admin` só
/// existem para quem entrou como administrador; para qualquer outra pessoa
/// elas caem na tela inicial, como se não existissem.
///
/// | Rota                  | Tela                        |
/// |-----------------------|-----------------------------|
/// | `/`                   | inicial do aluno            |
/// | `/historico`          | histórico de estudo         |
/// | `/historico/:id`      | resolução de uma questão    |
/// | `/perfil`             | perfil e acessos            |
/// | `/materias`           | escolha de matéria          |
/// | `/sessao`             | questão sendo feita         |
/// | `/sessao?questao=:id` | refazer uma questão         |
/// | `/login`, `/cadastro` | entrar e criar conta        |
/// | `/admin/...`          | painel administrativo       |
final routerProvider = Provider<GoRouter>((ref) {
  // Um ValueNotifier para o go_router reavaliar as rotas quando alguém entra
  // ou sai, sem que ele precise conhecer o Riverpod.
  final sessao = ValueNotifier<Usuario?>(ref.read(usuarioProvider));
  ref.listen(usuarioProvider, (_, atual) => sessao.value = atual);
  ref.onDispose(sessao.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: sessao,
    redirect: (_, estado) {
      final usuario = sessao.value;
      final local = estado.matchedLocation;

      // Painel administrativo: invisível e inacessível para quem não é do
      // grupo. Vai para a tela inicial em vez de avisar que a rota existe.
      if (local.startsWith('/admin')) {
        return (usuario?.isAdmin ?? false) ? null : '/';
      }

      // Estudar exige conta; depois do login a pessoa volta para a questão.
      if (local == '/sessao' && usuario == null) {
        final destino = Uri.encodeComponent(estado.uri.toString());
        return '/login?apos=$destino';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => CascaAluno(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/historico',
                builder: (_, _) => const HistoricoScreen(),
                routes: [
                  GoRoute(
                    path: ':idQuestao',
                    builder: (_, estado) => HistoricoDetalheScreen(
                      idQuestao:
                          int.tryParse(
                            estado.pathParameters['idQuestao'] ?? '',
                          ) ??
                          0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/perfil', builder: (_, _) => const PerfilScreen()),
            ],
          ),
        ],
      ),
      GoRoute(path: '/materias', builder: (_, _) => const MateriasScreen()),
      GoRoute(
        path: '/sessao',
        builder: (_, estado) => SessaoScreen(
          idQuestao: int.tryParse(estado.uri.queryParameters['questao'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, estado) =>
            LoginScreen(apos: estado.uri.queryParameters['apos']),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (_, estado) =>
            CadastroScreen(apos: estado.uri.queryParameters['apos']),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'materias',
            builder: (_, _) => const AdminMateriasScreen(),
          ),
          GoRoute(
            path: 'assuntos',
            builder: (_, _) => const AdminAssuntosScreen(),
          ),
          GoRoute(path: 'grafo', builder: (_, _) => const AdminGrafoScreen()),
          GoRoute(
            path: 'questoes',
            builder: (_, _) => const AdminQuestoesScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, estado) => Scaffold(
      appBar: AppBar(title: const Text('Tela não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rota ${estado.uri} não existe.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Ir para o início'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
