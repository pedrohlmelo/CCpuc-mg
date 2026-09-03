import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_assuntos_screen.dart';
import '../../features/admin/presentation/admin_grafo_screen.dart';
import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_materias_screen.dart';
import '../../features/admin/presentation/admin_questoes_screen.dart';
import '../../features/autenticacao/application/sessao_controller.dart';
import '../../features/autenticacao/domain/usuario.dart';
import '../../features/autenticacao/presentation/cadastro_screen.dart';
import '../../features/autenticacao/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/materias/presentation/escolha_materia_screen.dart';
import '../../features/questoes/presentation/sessao_screen.dart';

const _rotasPublicas = {'/login', '/cadastro'};

final routerProvider = Provider<GoRouter>((ref) {
  final sessao = ValueNotifier<Usuario?>(ref.read(sessaoProvider));
  ref.listen(sessaoProvider, (_, atual) => sessao.value = atual);
  ref.onDispose(sessao.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: sessao,
    redirect: (_, state) {
      final usuario = sessao.value;
      final local = state.matchedLocation;
      final publica = _rotasPublicas.contains(local);

      if (usuario == null) return publica ? null : '/login';
      if (publica) return usuario.isAdmin ? '/admin' : '/materias';
      if (local.startsWith('/admin') && !usuario.isAdmin) return '/materias';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/cadastro', builder: (_, _) => const CadastroScreen()),
      GoRoute(
        path: '/materias',
        builder: (_, _) => const EscolhaMateriaScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/sessao', builder: (_, _) => const SessaoScreen()),
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
  );
});
