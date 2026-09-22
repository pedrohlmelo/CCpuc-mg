import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/dados_exemplo.dart';
import '../../dados/estado_prototipo.dart';
import '../../dados/modelos.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/marca.dart';
import '../../widgets/mascote.dart';
import '../../widgets/saude_memoria.dart';

/// Tela inicial do aluno: saudação, resumo, saúde da memória, atalho para o
/// histórico e o botão principal de estudar. Primeira tela do app — não há
/// login antes dela.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nome = ref.watch(nomeAlunoProvider);
    final materia = ref.watch(materiaSelecionadaProvider);
    final historico = ref.watch(historicoProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final respondidas = historico.length;
    final acertos = historico.where(respostaCerta).length;
    final taxa = respondidas == 0 ? 0 : (acertos / respondidas * 100).round();
    final emRisco = saudeExemplo
        .where((s) => s.estado != EstadoMemoria.consolidado)
        .toList();

    return Scaffold(
      key: const Key('tela_inicial'),
      appBar: AppBar(
        title: const MarcaAdapta(compacto: true),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá, $nome', style: texto.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Pronto para mais um passo?',
                      style: texto.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ActionChip(
                      key: const Key('chip_materia'),
                      avatar: Icon(
                        materia == null
                            ? Icons.auto_awesome_rounded
                            : Icons.filter_alt_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      label: Text(materia?.nome ?? 'Estudo guiado'),
                      onPressed: () => context.push('/materias'),
                    ),
                  ],
                ),
              ),
              const MascoteAnimado(tamanho: 96),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TileEstatistica(
                    valor: '$respondidas',
                    rotulo: 'questões respondidas',
                    icone: Icons.quiz_rounded,
                    cor: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TileEstatistica(
                    valor: '$taxa%',
                    rotulo: 'de acerto',
                    icone: Icons.track_changes_rounded,
                    cor: AppCores.teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (emRisco.isNotEmpty) ...[
            _AlertaRevisao(assunto: emRisco.first),
            const SizedBox(height: 24),
          ],
          const TituloSecao('Saúde da memória'),
          AppCartao(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Column(
              children: [
                for (final s in saudeExemplo)
                  BarraSaude(
                    nome: s.nome,
                    retencao: s.retencao,
                    cor: corDaMemoria(s.estado),
                    rotulo: rotuloDaMemoria(s.estado),
                  ),
                const SizedBox(height: 6),
                const LegendaMemoria(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const TituloSecao('Em breve'),
          AppCartao(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _LinhaFutura(
                  icone: Icons.account_tree_rounded,
                  cor: AppCores.violeta,
                  titulo: 'Mapa de conhecimento',
                  descricao: 'Seu grafo de assuntos colorido pela memória.',
                ),
                Divider(color: scheme.outline, height: 1, indent: 72),
                const _LinhaFutura(
                  icone: Icons.route_rounded,
                  cor: AppCores.teal,
                  titulo: 'Trilha até um objetivo',
                  descricao: 'Caminho mais curto do que você sabe até a meta.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de assunto prestes a ser esquecido (texto de exemplo).
class _AlertaRevisao extends StatelessWidget {
  final SaudeAssunto assunto;
  const _AlertaRevisao({required this.assunto});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final critico = assunto.estado == EstadoMemoria.critico;
    final cor = corDaMemoria(assunto.estado);
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

/// Tela ainda não desenhada, anunciada na home.
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
            child: Text('Próxima etapa', style: texto.labelSmall),
          ),
        ],
      ),
    );
  }
}
