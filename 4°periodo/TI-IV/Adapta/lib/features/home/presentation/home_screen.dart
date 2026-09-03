import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tema/app_tema.dart';
import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/marca.dart';
import '../../../core/widgets/mascote.dart';
import '../../../pilares/esquecimento/previsor_esquecimento.dart';
import '../../autenticacao/application/sessao_controller.dart';
import '../../materias/data/materia_repository.dart';
import '../data/painel_memoria_provider.dart';

/// Tela inicial: saudação, saúde da memória, alertas e o botão principal.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessaoProvider);
    final materia = ref.watch(materiaSelecionadaProvider);
    final resumo = ref.watch(resumoAlunoProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const MarcaAdapta(compacto: true),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(resumoAlunoProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${usuario?.nome.split(' ').first ?? ''}',
                        style: texto.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pronto para mais um passo?',
                        style: texto.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ActionChip(
                        avatar: Icon(
                          materia == null
                              ? Icons.auto_awesome_rounded
                              : Icons.filter_alt_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        label: Text(materia?.nome ?? 'Estudo guiado'),
                        onPressed: () => context.go('/materias'),
                      ),
                    ],
                  ),
                ),
                const MascoteAnimado(tamanho: 96),
              ],
            ),
            const SizedBox(height: 20),
            resumo.when(
              loading: () => const SizedBox(height: 120, child: Carregando()),
              error: (e, _) => AppCartao(child: Text('Erro: $e')),
              data: (r) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TileEstatistica(
                            valor: '${r.respondidas}',
                            rotulo: 'questões respondidas',
                            icone: Icons.quiz_rounded,
                            cor: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TileEstatistica(
                            valor: '${(r.taxaAcerto * 100).round()}%',
                            rotulo: 'de acerto',
                            icone: Icons.track_changes_rounded,
                            cor: AppCores.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (r.emRisco.isNotEmpty) ...[
                    _AlertaRevisao(assunto: r.emRisco.first),
                    const SizedBox(height: 24),
                  ],
                  const TituloSecao('Saúde da memória'),
                  AppCartao(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    child: r.assuntos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Mascote(
                                  pose: PoseCamu.pensativo,
                                  tamanho: 64,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Ainda não há nada aqui. Responda algumas questões e eu começo a acompanhar o que você lembra.',
                                    style: texto.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              for (final a in r.assuntos.take(6))
                                BarraSaude(
                                  nome: a.nome,
                                  retencao: a.retencao,
                                  cor: _cor(a.saude),
                                  rotulo: _rotulo(a.saude),
                                ),
                              const SizedBox(height: 6),
                              const _Legenda(),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  const TituloSecao('Em breve'),
                  AppCartao(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _LinhaFutura(
                          icone: Icons.account_tree_rounded,
                          cor: AppCores.violeta,
                          titulo: 'Mapa de conhecimento',
                          descricao:
                              'Seu grafo de assuntos colorido pela memória.',
                        ),
                        Divider(color: scheme.outline, height: 1, indent: 72),
                        _LinhaFutura(
                          icone: Icons.route_rounded,
                          cor: AppCores.teal,
                          titulo: 'Trilha até um objetivo',
                          descricao:
                              'Caminho mais curto do que você sabe até a meta.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('botao_estudar'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              elevation: 6,
              shadowColor: scheme.primary.withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Estudar agora'),
            onPressed: () => context.go('/sessao'),
          ),
        ),
      ),
    );
  }

  static Color _cor(SaudeMemoria s) => switch (s) {
    SaudeMemoria.consolidado => CoresMemoria.consolidado,
    SaudeMemoria.emRisco => CoresMemoria.emRisco,
    SaudeMemoria.critico => CoresMemoria.critico,
    SaudeMemoria.naoEstudado => CoresMemoria.naoEstudado,
  };

  static String _rotulo(SaudeMemoria s) => switch (s) {
    SaudeMemoria.consolidado => 'Consolidado',
    SaudeMemoria.emRisco => 'Em risco',
    SaudeMemoria.critico => 'Crítico',
    SaudeMemoria.naoEstudado => 'Não estudado',
  };
}

class _AlertaRevisao extends StatelessWidget {
  final SaudeAssunto assunto;
  const _AlertaRevisao({required this.assunto});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final critico = assunto.saude == SaudeMemoria.critico;
    final cor = critico ? CoresMemoria.critico : CoresMemoria.emRisco;
    final chance = ((1 - assunto.retencao) * 100).round().clamp(1, 99);
    return AppCartao(
      cor: cor.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconeCaixa(
            icone: critico
                ? Icons.warning_amber_rounded
                : Icons.schedule_rounded,
            cor: cor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  critico ? 'Revise hoje' : 'Revisão recomendada',
                  style: texto.titleSmall?.copyWith(color: cor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Você tem $chance% de chance de esquecer ${assunto.nome}.',
                  style: texto.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(t, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(CoresMemoria.consolidado, 'Consolidado'),
        item(CoresMemoria.emRisco, 'Em risco'),
        item(CoresMemoria.critico, 'Crítico'),
      ],
    );
  }
}

class _LinhaFutura extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;

  const _LinhaFutura({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconeCaixa(icone: icone, cor: cor, tamanho: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: texto.titleSmall),
                Text(descricao, style: texto.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('Sprint 3', style: texto.labelSmall),
          ),
        ],
      ),
    );
  }
}
