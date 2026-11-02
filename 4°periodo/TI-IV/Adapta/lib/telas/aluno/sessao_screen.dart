import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/questao_widget.dart';

/// Sessão de estudo: uma questão por vez, com feedback e explicação.
///
/// Sem [idQuestao] percorre as questões da matéria escolhida. Com [idQuestao]
/// abre só aquela, que é o caminho do botão "Refazer esta questão" do
/// histórico.
class SessaoScreen extends ConsumerStatefulWidget {
  final int? idQuestao;

  /// Com valor, a sessão fica só neste assunto (vem do mapa).
  final int? idAssunto;
  const SessaoScreen({this.idQuestao, this.idAssunto, super.key});

  @override
  ConsumerState<SessaoScreen> createState() => _SessaoScreenState();
}

class _SessaoScreenState extends ConsumerState<SessaoScreen> {
  int _indice = 0;
  List<Questao>? _fila;
  final _cronometro = Stopwatch();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final conteudo = await ref.read(conteudoProvider.future);
    final unica = widget.idQuestao == null
        ? null
        : conteudo.questaoPorId(widget.idQuestao!);
    if (!mounted) return;
    setState(() {
      final assunto = widget.idAssunto;
      _fila = unica != null
          ? [unica]
          : assunto != null
          ? conteudo.questoes.where((q) => q.idAssunto == assunto).toList()
          : conteudo.questoesDaMateria(ref.read(idMateriaSelecionadaProvider));
    });
    _cronometro.start();
  }

  void _responder(Questao questao, Alternativa escolhida) {
    ref
        .read(historicoProvider.notifier)
        .registrar(
          idQuestao: questao.id,
          letra: escolhida.letra,
          acertou: escolhida.correta,
          tempoGasto: _cronometro.elapsed.inSeconds,
        );
  }

  void _avancar() {
    _cronometro.reset();
    setState(() => _indice++);
  }

  void _verHistorico() {
    // Fecha a sessão antes de trocar de aba, para não deixá-la na pilha.
    if (context.canPop()) context.pop();
    context.go('/historico');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refazendo = widget.idQuestao != null;
    final fila = _fila ?? const <Questao>[];
    final total = fila.length;
    final acabou = _indice >= total;

    return Scaffold(
      key: const Key('tela_sessao'),
      appBar: AppBar(
        leading: const BotaoVoltar.fechar(),
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: total == 0 ? 0 : (_indice / total).clamp(0, 1),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                color: scheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          const BotaoTema(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_indice.clamp(0, total)}/$total',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: _fila == null
          ? const Carregando()
          : total == 0
          ? EstadoVazio(
              ilustracao: const Mascote(pose: PoseCamu.pensativo, tamanho: 140),
              titulo: 'Nenhuma questão nesta matéria',
              descricao: 'Escolha outra matéria para continuar.',
              acao: FilledButton(
                onPressed: () => context.go('/materias'),
                child: const Text('Escolher matéria'),
              ),
            )
          : acabou
          ? EstadoVazio(
              ilustracao: const MascoteAnimado(
                pose: PoseCamu.feliz,
                tamanho: 150,
              ),
              titulo: refazendo ? 'Questão refeita' : 'Sessão concluída',
              descricao: refazendo
                  ? 'A nova tentativa entrou no seu histórico.'
                  : 'Você respondeu todas as questões desta fila.',
              acao: Column(
                children: [
                  FilledButton.icon(
                    key: const Key('botao_ver_historico'),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Ver histórico'),
                    onPressed: _verHistorico,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    child: const Text('Voltar ao início'),
                  ),
                ],
              ),
            )
          : QuestaoWidget(
              key: ValueKey(fila[_indice].id),
              questao: fila[_indice],
              aoResponder: (escolhida) => _responder(fila[_indice], escolhida),
              aoAvancar: _avancar,
              rotuloAvancar: _indice == total - 1 ? 'Concluir' : 'Continuar',
            ),
    );
  }
}
