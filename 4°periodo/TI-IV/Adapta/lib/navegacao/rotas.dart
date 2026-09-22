import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
/// abertura e nenhuma rota exige sessão. Login, cadastro e painel admin são
/// alcançados pela aba Perfil e abrem por cima, sempre com botão de voltar.
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
  return GoRouter(
    initialLocation: '/',
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
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (_, _) => const CadastroScreen()),
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
