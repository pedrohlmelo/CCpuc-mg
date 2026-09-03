import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tema/app_tema.dart';
import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/marca.dart';
import '../../../core/widgets/mascote.dart';
import '../../../core/widgets/rodape_copyright.dart';
import '../../autenticacao/application/sessao_controller.dart';
import '../data/admin_repository.dart';

/// RF11 — painel administrativo (uso interno do grupo).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumo = ref.watch(resumoAdminProvider);
    final usuario = ref.watch(sessaoProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const MarcaAdapta(compacto: true),
        actions: [
          IconButton(
            tooltip: 'Ver como aluno',
            icon: const Icon(Icons.school_outlined),
            onPressed: () => context.go('/materias'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(resumoAdminProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            CartaoGradiente(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'USO INTERNO',
                            style: texto.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Painel administrativo',
                          style: texto.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Olá, ${usuario?.nome ?? ''}. Aqui você cuida do conteúdo e do grafo.',
                          style: texto.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Mascote(tamanho: 96),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TituloSecao('Visão geral'),
            resumo.when(
              loading: () => const SizedBox(height: 120, child: Carregando()),
              error: (e, _) => AppCartao(child: Text('Erro: $e')),
              data: (r) => GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  TileEstatistica(
                    valor: '${r.materias}',
                    rotulo: 'matérias',
                    icone: Icons.menu_book_rounded,
                    cor: scheme.primary,
                  ),
                  TileEstatistica(
                    valor: '${r.assuntos}',
                    rotulo: 'assuntos (vértices)',
                    icone: Icons.hub_rounded,
                    cor: AppCores.violeta,
                  ),
                  TileEstatistica(
                    valor: '${r.dependencias}',
                    rotulo: 'dependências (arestas)',
                    icone: Icons.account_tree_rounded,
                    cor: AppCores.teal,
                  ),
                  TileEstatistica(
                    valor: '${r.questoes}',
                    rotulo: 'questões',
                    icone: Icons.quiz_rounded,
                    cor: const Color(0xFFF59E0B),
                  ),
                  TileEstatistica(
                    valor: '${r.alunos}',
                    rotulo: 'alunos',
                    icone: Icons.people_alt_rounded,
                    cor: const Color(0xFFDB2777),
                  ),
                  TileEstatistica(
                    valor: '${r.respostas}',
                    rotulo: 'respostas registradas',
                    icone: Icons.timeline_rounded,
                    cor: const Color(0xFF0EA5E9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TituloSecao('Gerenciar'),
            AppCartao(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ItemMenu(
                    icone: Icons.menu_book_rounded,
                    cor: scheme.primary,
                    titulo: 'Matérias',
                    descricao: 'Cadastrar e listar matérias',
                    rota: '/admin/materias',
                  ),
                  Divider(height: 1, indent: 72, color: scheme.outline),
                  _ItemMenu(
                    icone: Icons.hub_rounded,
                    cor: AppCores.violeta,
                    titulo: 'Assuntos',
                    descricao: 'Vértices do grafo, por matéria',
                    rota: '/admin/assuntos',
                  ),
                  Divider(height: 1, indent: 72, color: scheme.outline),
                  _ItemMenu(
                    icone: Icons.account_tree_rounded,
                    cor: AppCores.teal,
                    titulo: 'Grafo de dependências',
                    descricao:
                        'Pré-requisito → dependente, com validação de ciclo',
                    rota: '/admin/grafo',
                  ),
                  Divider(height: 1, indent: 72, color: scheme.outline),
                  _ItemMenu(
                    icone: Icons.quiz_rounded,
                    cor: const Color(0xFFF59E0B),
                    titulo: 'Questões',
                    descricao: 'Banco de questões e alternativas',
                    rota: '/admin/questoes',
                  ),
                ],
              ),
            ),
            const RodapeCopyright(),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final String rota;

  const _ItemMenu({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.rota,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: IconeCaixa(icone: icone, cor: cor, tamanho: 40),
      title: Text(titulo),
      subtitle: Text(descricao),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(rota),
    );
  }
}
