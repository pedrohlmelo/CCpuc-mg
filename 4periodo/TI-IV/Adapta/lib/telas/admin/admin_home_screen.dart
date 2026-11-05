import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../aluno/materias_screen.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/rodape_copyright.dart';

/// Menu do painel administrativo (RF11), de uso interno do grupo. Chega-se
/// aqui pela aba Perfil, e o botão de voltar retorna ao app do aluno.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final dependencias = ref.watch(dependenciasProvider).valueOrNull;
    final pendentes = ref.watch(pendentesAdminProvider).valueOrNull ?? 0;
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('tela_admin_menu'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Painel administrativo'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
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
                        'Conteúdo e grafo',
                        style: texto.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matérias, assuntos, dependências e questões do Adapta.',
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
          GridView(
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
                valor: '${conteudo?.materias.length ?? 0}',
                rotulo: 'matérias',
                icone: Icons.menu_book_rounded,
                cor: scheme.primary,
              ),
              TileEstatistica(
                valor: '${conteudo?.assuntos.length ?? 0}',
                rotulo: 'assuntos (vértices)',
                icone: Icons.hub_rounded,
                cor: AppCores.violeta,
              ),
              TileEstatistica(
                valor: '${dependencias?.length ?? 0}',
                rotulo: 'dependências (arestas)',
                icone: Icons.account_tree_rounded,
                cor: AppCores.teal,
              ),
              TileEstatistica(
                valor: '${conteudo?.questoes.length ?? 0}',
                rotulo: 'questões',
                icone: Icons.quiz_rounded,
                cor: const Color(0xFFF59E0B),
              ),
            ],
          ),
          if (conteudo != null) ...[
            const SizedBox(height: 12),
            AppCartao(
              key: const Key('situacao_conteudo'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LinhaSituacao(
                    'Matérias',
                    conteudo.materias.length,
                    conteudo.todasMaterias.length - conteudo.materias.length,
                  ),
                  _LinhaSituacao(
                    'Assuntos',
                    conteudo.assuntos.length,
                    conteudo.todosAssuntos.length - conteudo.assuntos.length,
                  ),
                  _LinhaSituacao(
                    'Questões',
                    conteudo.questoes.length,
                    conteudo.inativas.length,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Não revisadas: '
                    '${conteudo.questoes.where((q) => !q.revisado).length}',
                    style: texto.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        pendentes == 0
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 18,
                        color: pendentes == 0
                            ? AppCores.teal
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pendentes == 0
                              ? 'Tudo enviado à nuvem'
                              : '$pendentes alterações pendentes de envio',
                          key: const Key('pendentes_admin'),
                          style: texto.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TituloSecao('Questões por matéria'),
            AppCartao(
              key: const Key('contadores_conteudo'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (area, nome) in areasDoEnem) ...[
                    Text(
                      '$nome: ${_totalDaArea(conteudo, area)}',
                      style: texto.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    for (final m in conteudo.materias)
                      if (m.area == area)
                        Text(
                          '${m.nome}: '
                          '${conteudo.questoesDaMateria(m.id).length}',
                          style: texto.bodySmall,
                        ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Não revisadas: '
                    '${conteudo.questoes.where((q) => !q.revisado).length}',
                    style: texto.titleSmall,
                  ),
                ],
              ),
            ),
          ],
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
                  descricao: 'Criar, editar e excluir matérias',
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
                  descricao: 'Pré-requisito → dependente',
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
    );
  }
}

class _LinhaSituacao extends StatelessWidget {
  final String nome;
  final int ativos;
  final int inativos;
  const _LinhaSituacao(this.nome, this.ativos, this.inativos);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      '$nome: $ativos ativos · $inativos inativos',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

int _totalDaArea(Conteudo conteudo, String area) => conteudo.materias
    .where((m) => m.area == area)
    .fold(0, (total, m) => total + conteudo.questoesDaMateria(m.id).length);

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
      key: Key('menu_admin_$rota'),
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: IconeCaixa(icone: icone, cor: cor, tamanho: 40),
      title: Text(titulo),
      subtitle: Text(descricao),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(rota),
    );
  }
}
