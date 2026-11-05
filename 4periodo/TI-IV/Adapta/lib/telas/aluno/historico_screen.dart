import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
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
    final historico = ref.watch(historicoProvider).valueOrNull ?? const [];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final respondidas = historico.length;
    final acertos = historico.where((r) => r.acertou).length;
    final taxa = respondidas == 0 ? 0 : (acertos / respondidas * 100).round();

    final lista = switch (_filtro) {
      _Filtro.tudo => historico,
      _Filtro.acertos => historico.where((r) => r.acertou).toList(),
      _Filtro.erros => historico.where((r) => !r.acertou).toList(),
    };

    return Scaffold(
      key: const Key('tela_historico'),
      appBar: AppBar(
        title: const Text('Histórico de estudo'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: historico.isEmpty
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
                _DesempenhoPorMateria(historico: historico),
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

class _ItemHistorico extends ConsumerWidget {
  final Resposta resposta;
  const _ItemHistorico({required this.resposta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final questao = conteudo?.questaoPorId(resposta.idQuestao);
    if (questao == null) return const SizedBox.shrink();

    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final certa = resposta.acertou;
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
                  conteudo!.nomeDoAssunto(questao.idAssunto),
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

/// Respondidas e acertos de um grupo de respostas.
class _Placar {
  int respondidas = 0;
  int acertos = 0;

  int get taxa => respondidas == 0 ? 0 : (acertos / respondidas * 100).round();

  void somar(Resposta r) {
    respondidas++;
    if (r.acertou) acertos++;
  }
}

/// RF10: desempenho por matéria a partir do histórico local. Tocar numa
/// matéria abre os assuntos dela, com os mesmos números.
class _DesempenhoPorMateria extends ConsumerStatefulWidget {
  final List<Resposta> historico;
  const _DesempenhoPorMateria({required this.historico});

  @override
  ConsumerState<_DesempenhoPorMateria> createState() =>
      _DesempenhoPorMateriaState();
}

class _DesempenhoPorMateriaState extends ConsumerState<_DesempenhoPorMateria> {
  int? _aberta;

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    if (conteudo == null) return const SizedBox.shrink();
    final texto = Theme.of(context).textTheme;

    final porMateria = <int, _Placar>{};
    final porAssunto = <int, _Placar>{};
    for (final r in widget.historico) {
      final q = conteudo.questaoPorId(r.idQuestao);
      if (q == null) continue;
      final m = conteudo.materiaDaQuestao(q);
      if (m == null) continue;
      (porMateria[m.id] ??= _Placar()).somar(r);
      (porAssunto[q.idAssunto] ??= _Placar()).somar(r);
    }
    if (porMateria.isEmpty) return const SizedBox.shrink();
    final materias = porMateria.keys.toList()
      ..sort(
        (a, b) =>
            porMateria[b]!.respondidas.compareTo(porMateria[a]!.respondidas),
      );

    return Column(
      key: const Key('desempenho_por_materia'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Desempenho por matéria', style: texto.titleSmall),
        const SizedBox(height: 10),
        AppCartao(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final id in materias) ...[
                _LinhaDesempenho(
                  key: Key('desempenho_materia_$id'),
                  nome: conteudo.materiaPorId(id)?.nome ?? 'Matéria #$id',
                  placar: porMateria[id]!,
                  aberta: _aberta == id,
                  aoTocar: () =>
                      setState(() => _aberta = _aberta == id ? null : id),
                ),
                if (_aberta == id)
                  for (final a in porAssunto.keys.where(
                    (a) => conteudo.assuntoPorId(a)?.idMateria == id,
                  ))
                    _LinhaDesempenho(
                      key: Key('desempenho_assunto_$a'),
                      nome: conteudo.nomeDoAssunto(a),
                      placar: porAssunto[a]!,
                      recuo: true,
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LinhaDesempenho extends StatelessWidget {
  final String nome;
  final _Placar placar;
  final bool recuo;
  final bool aberta;
  final VoidCallback? aoTocar;

  const _LinhaDesempenho({
    super.key,
    required this.nome,
    required this.placar,
    this.recuo = false,
    this.aberta = false,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final taxa = placar.taxa;
    final cor = taxa >= 70
        ? CoresMemoria.consolidado
        : taxa >= 40
        ? CoresMemoria.emRisco
        : CoresMemoria.critico;
    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: EdgeInsets.fromLTRB(recuo ? 32 : 16, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nome,
                    style: recuo ? texto.bodyMedium : texto.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${placar.respondidas} resp. · $taxa%',
                  style: texto.labelMedium,
                ),
                if (aoTocar != null)
                  Icon(
                    aberta
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: taxa / 100,
                minHeight: 6,
                color: cor,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
