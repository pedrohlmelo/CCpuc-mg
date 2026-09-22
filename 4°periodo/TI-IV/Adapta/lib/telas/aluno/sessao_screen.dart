import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/dados_exemplo.dart';
import '../../dados/estado_prototipo.dart';
import '../../dados/modelos.dart';
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
  const SessaoScreen({this.idQuestao, super.key});

  @override
  ConsumerState<SessaoScreen> createState() => _SessaoScreenState();
}

class _SessaoScreenState extends ConsumerState<SessaoScreen> {
  int _indice = 0;
  late final List<Questao> _fila;

  @override
  void initState() {
    super.initState();
    final unica = widget.idQuestao == null
        ? null
        : questaoPorId(widget.idQuestao!);
    if (unica != null) {
      _fila = [unica];
    } else {
      final materia = ref.read(materiaSelecionadaProvider);
      _fila = questoesDaMateria(materia?.id);
    }
  }

  void _responder(Questao questao, Alternativa escolhida) {
    ref
        .read(historicoProvider.notifier)
        .registrar(idQuestao: questao.id, letra: escolhida.letra);
  }

  void _avancar() => setState(() => _indice++);

  void _verHistorico() {
    // Fecha a sessão antes de trocar de aba, para não deixá-la na pilha.
    if (context.canPop()) context.pop();
    context.go('/historico');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refazendo = widget.idQuestao != null;
    final total = _fila.length;
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
      body: total == 0
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
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/'),
                    child: const Text('Voltar ao início'),
                  ),
                ],
              ),
            )
          : QuestaoWidget(
              key: ValueKey(_fila[_indice].id),
              questao: _fila[_indice],
              aoResponder: (escolhida) => _responder(_fila[_indice], escolhida),
              aoAvancar: _avancar,
              rotuloAvancar: _indice == total - 1 ? 'Concluir' : 'Continuar',
            ),
    );
  }
}
