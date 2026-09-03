import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../../../pilares/recomendacao/recomendador.dart';
import '../../autenticacao/application/sessao_controller.dart';
import '../../home/data/painel_memoria_provider.dart';
import '../../materias/data/materia_repository.dart';
import '../data/historico_repository.dart';
import '../domain/questao.dart';
import 'questao_widget.dart';

/// Próxima questão sugerida pelo recomendador para o aluno logado.
final proximaQuestaoProvider = FutureProvider.autoDispose<Questao?>((ref) {
  final usuario = ref.watch(sessaoProvider);
  if (usuario == null) return null;
  final materia = ref.watch(materiaSelecionadaProvider);
  return ref
      .watch(recomendadorProvider)
      .proximaQuestao(idUsuario: usuario.id, idMateria: materia?.id);
});

/// Contador de respostas na sessão atual (só para a barra de progresso).
final respondidasNaSessaoProvider = StateProvider.autoDispose<int>((_) => 0);

/// RF04 / RF05 — sessão de estudo: uma questão por vez, feedback, avança.
class SessaoScreen extends ConsumerWidget {
  const SessaoScreen({super.key});

  static const metaSessao = 10;

  Future<void> _responder(WidgetRef ref, Questao questao, bool acertou) async {
    final usuario = ref.read(sessaoProvider);
    if (usuario == null) return;
    await ref
        .read(historicoRepositoryProvider)
        .registrar(
          idUsuario: usuario.id,
          idQuestao: questao.id,
          acertou: acertou,
        );
    ref.read(respondidasNaSessaoProvider.notifier).state++;
    ref.invalidate(resumoAlunoProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxima = ref.watch(proximaQuestaoProvider);
    final feitas = ref.watch(respondidasNaSessaoProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (feitas / metaSessao).clamp(0, 1)),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$feitas/$metaSessao',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: proxima.when(
        loading: () => const Carregando(),
        error: (e, _) =>
            EstadoVazio(titulo: 'Algo deu errado', descricao: '$e'),
        data: (questao) {
          if (questao == null) {
            return EstadoVazio(
              ilustracao: const MascoteAnimado(
                pose: PoseCamu.feliz,
                tamanho: 150,
              ),
              titulo: 'Você zerou as questões disponíveis',
              descricao:
                  'Por enquanto é tudo. Em breve o Camu vai trazer revisões no momento certo.',
              acao: FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Voltar ao início'),
              ),
            );
          }
          return QuestaoWidget(
            key: ValueKey(questao.id),
            questao: questao,
            aoResponder: (acertou) => _responder(ref, questao, acertou),
            aoAvancar: () => ref.invalidate(proximaQuestaoProvider),
          );
        },
      ),
    );
  }
}
