import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/dados_exemplo.dart';
import '../../dados/estado_prototipo.dart';
import '../../dados/modelos.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/formato_data.dart';
import '../../widgets/mascote.dart';

enum _Filtro { tudo, acertos, erros }

/// Histórico de estudo: tudo que o aluno já respondeu, agrupado por dia.
/// Tocar em um item abre a resolução antiga, com a opção de refazer a questão.
class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  _Filtro _filtro = _Filtro.tudo;

  @override
  Widget build(BuildContext context) {
    final historico = ref.watch(historicoProvider);
    final entrou = ref.watch(entrouProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final respondidas = historico.length;
    final acertos = historico.where(respostaCerta).length;
    final taxa = respondidas == 0 ? 0 : (acertos / respondidas * 100).round();

    final lista = switch (_filtro) {
      _Filtro.tudo => historico,
      _Filtro.acertos => historico.where(respostaCerta).toList(),
      _Filtro.erros => historico.where((r) => !respostaCerta(r)).toList(),
    };

    return Scaffold(
      key: const Key('tela_historico'),
      appBar: AppBar(
        title: const Text('Histórico de estudo'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: !entrou
          ? EstadoVazio(
              ilustracao: const Mascote(pose: PoseCamu.pensativo, tamanho: 130),
              titulo: 'Seu histórico fica guardado na sua conta',
              descricao:
                  'Entre para ver as questões que você respondeu e rever as resoluções.',
              acao: FilledButton(
                key: const Key('botao_entrar_historico'),
                onPressed: () => context.push('/login'),
                child: const Text('Entrar'),
              ),
            )
          : historico.isEmpty
          ? const EstadoVazio(
              ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 130),
              titulo: 'Você ainda não respondeu nada',
              descricao:
                  'Quando você estudar, as questões e as resoluções aparecem aqui.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TileEstatistica(
                          valor: '$respondidas',
                          rotulo: 'questões respondidas',
                          icone: Icons.fact_check_rounded,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (final f in _Filtro.values) ...[
                      ChoiceChip(
                        key: Key('filtro_${f.name}'),
                        label: Text(switch (f) {
                          _Filtro.tudo => 'Tudo',
                          _Filtro.acertos => 'Acertos',
                          _Filtro.erros => 'Erros',
                        }),
                        selected: _filtro == f,
                        onSelected: (_) => setState(() => _filtro = f),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (lista.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      _filtro == _Filtro.erros
                          ? 'Nenhum erro por aqui.'
                          : 'Nenhum acerto por aqui.',
                      textAlign: TextAlign.center,
                      style: texto.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ..._porDia(lista),
              ],
            ),
    );
  }

  /// Agrupa as respostas por dia, com um subtítulo por grupo.
  List<Widget> _porDia(List<Resposta> lista) {
    final widgets = <Widget>[];
    String? diaAtual;
    for (final resposta in lista) {
      final dia = rotuloDoDia(resposta.quando);
      if (dia != diaAtual) {
        diaAtual = dia;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 20, bottom: 10),
            child: Text(dia, style: Theme.of(context).textTheme.titleSmall),
          ),
        );
      }
      widgets.add(_ItemHistorico(resposta: resposta));
      widgets.add(const SizedBox(height: 10));
    }
    return widgets;
  }
}

class _ItemHistorico extends StatelessWidget {
  final Resposta resposta;
  const _ItemHistorico({required this.resposta});

  @override
  Widget build(BuildContext context) {
    final questao = questaoPorId(resposta.idQuestao);
    if (questao == null) return const SizedBox.shrink();

    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final certa = respostaCerta(resposta);
    final cor = certa ? CoresMemoria.consolidado : CoresMemoria.critico;

    return AppCartao(
      key: Key('item_historico_${resposta.idQuestao}'),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      aoTocar: () => context.push('/historico/${resposta.idQuestao}'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              certa ? Icons.check_rounded : Icons.close_rounded,
              color: cor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeDoAssunto(questao.idAssunto),
                  style: texto.labelMedium?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  questao.enunciado,
                  style: texto.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${hora(resposta.quando)} · você marcou ${resposta.letraEscolhida}',
                  style: texto.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
