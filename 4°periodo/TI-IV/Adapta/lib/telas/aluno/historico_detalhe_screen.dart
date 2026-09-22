import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/dados_exemplo.dart';
import '../../dados/estado_prototipo.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/formato_data.dart';
import '../../widgets/mascote.dart';
import '../../widgets/questao_widget.dart';

/// Resolução de uma questão já respondida: enunciado, a alternativa que o aluno
/// marcou, o gabarito, a explicação e as tentativas anteriores. Daqui o aluno
/// pode refazer a questão.
class HistoricoDetalheScreen extends ConsumerWidget {
  final int idQuestao;
  const HistoricoDetalheScreen({required this.idQuestao, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questao = questaoPorId(idQuestao);
    final tentativas = ref
        .watch(historicoProvider)
        .where((r) => r.idQuestao == idQuestao)
        .toList();

    if (questao == null || tentativas.isEmpty) {
      return Scaffold(
        key: const Key('tela_resolucao'),
        appBar: AppBar(
          leading: const BotaoVoltar(),
          title: const Text('Resolução'),
        ),
        body: const EstadoVazio(
          ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 120),
          titulo: 'Questão não encontrada',
          descricao: 'Volte ao histórico e escolha outra questão.',
        ),
      );
    }

    final ultima = tentativas.first;
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final certa = respostaCerta(ultima);
    final cor = certa ? CoresMemoria.consolidado : CoresMemoria.critico;
    final materia = materiaDaQuestao(questao);

    return Scaffold(
      key: const Key('tela_resolucao'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Resolução'),
      ),
      // As duas ações ficam fixas no rodapé, sempre ao alcance.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/historico'),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const Key('botao_refazer'),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Refazer questão'),
                  onPressed: () => context.push('/sessao?questao=$idQuestao'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          AppCartao(
            cor: cor.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconeCaixa(
                  icone: certa ? Icons.check_rounded : Icons.close_rounded,
                  cor: cor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certa ? 'Você acertou' : 'Você errou',
                        style: texto.titleSmall?.copyWith(color: cor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Você marcou ${ultima.letraEscolhida}. '
                        'O gabarito é ${questao.gabarito.letra}.',
                        style: texto.bodyMedium,
                      ),
                      Text(diaEHora(ultima.quando), style: texto.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Etiqueta(
                nomeDoAssunto(questao.idAssunto),
                scheme.primary,
                Icons.hub_rounded,
              ),
              if (materia != null)
                _Etiqueta(
                  materia.nome,
                  AppCores.violeta,
                  Icons.menu_book_rounded,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // A mesma questão da sessão, em modo de leitura: alternativas
          // marcadas como ficaram na resposta do aluno.
          QuestaoWidget(
            questao: questao,
            escolhidaInicial: ultima.letraEscolhida,
            somenteLeitura: true,
          ),
          const SizedBox(height: 14),
          const TituloSecao('Explicação'),
          AppCartao(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(questao.explicacao, style: texto.bodyMedium),
                ),
              ],
            ),
          ),
          if (tentativas.length > 1) ...[
            const SizedBox(height: 24),
            TituloSecao('Tentativas (${tentativas.length})'),
            AppCartao(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final t in tentativas)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        respostaCerta(t)
                            ? Icons.check_circle_outline_rounded
                            : Icons.highlight_off_rounded,
                        color: respostaCerta(t)
                            ? CoresMemoria.consolidado
                            : CoresMemoria.critico,
                      ),
                      title: Text('Marcou ${t.letraEscolhida}'),
                      trailing: Text(
                        diaEHora(t.quando),
                        style: texto.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData icone;
  const _Etiqueta(this.texto, this.cor, this.icone);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 6),
        Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: cor),
        ),
      ],
    ),
  );
}
