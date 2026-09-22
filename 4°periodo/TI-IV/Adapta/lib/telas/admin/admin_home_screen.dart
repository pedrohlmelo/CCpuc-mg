import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dados/dados_exemplo.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/rodape_copyright.dart';

/// Menu do painel administrativo (RF11), de uso interno do grupo. Chega-se
/// aqui pela aba Perfil, e o botão de voltar retorna ao app do aluno.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                valor: '${materiasExemplo.length}',
                rotulo: 'matérias',
                icone: Icons.menu_book_rounded,
                cor: scheme.primary,
              ),
              TileEstatistica(
                valor: '${assuntosExemplo.length}',
                rotulo: 'assuntos (vértices)',
                icone: Icons.hub_rounded,
                cor: AppCores.violeta,
              ),
              TileEstatistica(
                valor: '${dependenciasExemplo.length}',
                rotulo: 'dependências (arestas)',
                icone: Icons.account_tree_rounded,
                cor: AppCores.teal,
              ),
              TileEstatistica(
                valor: '${questoesExemplo.length}',
                rotulo: 'questões',
                icone: Icons.quiz_rounded,
                cor: const Color(0xFFF59E0B),
              ),
            ],
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
