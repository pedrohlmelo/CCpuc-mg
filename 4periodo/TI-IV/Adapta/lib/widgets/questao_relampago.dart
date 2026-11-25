import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dados/estado_app.dart';
import '../ia/montador_fila.dart';
import '../ia/servico_aprendizado.dart';

/// Busca a primeira questão da fila adaptativa e mostra, num painel, por que
/// a IA a escolheu. "Responder" abre a sessão só com ela.
Future<void> abrirQuestaoRelampago(BuildContext context, WidgetRef ref) async {
  HapticFeedback.mediumImpact();
  final usuario = await ref.read(sessaoProvider.future);
  final servico = await ref.read(servicoAprendizadoProvider.future);
  final relampago = await servico.questaoRelampago(
    usuario,
    idMateria: ref.read(idMateriaSelecionadaProvider),
    idMateriaOculta: ref.read(idMateriaOcultaProvider),
  );
  if (relampago == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => PainelRelampago(relampago: relampago),
  );
}

class PainelRelampago extends StatelessWidget {
  final QuestaoRelampago relampago;
  const PainelRelampago({required this.relampago, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final (icone, rotulo, cor) = switch (relampago.motivo) {
      MotivoFila.causaRaiz => (
        Icons.account_tree_rounded,
        'Lacuna de pré-requisito',
        scheme.error,
      ),
      MotivoFila.revisao => (
        Icons.history_edu_rounded,
        'Revisão antes de esquecer',
        scheme.tertiary,
      ),
      MotivoFila.nova => (
        Icons.trending_up_rounded,
        'Conteúdo novo no seu nível',
        scheme.primary,
      ),
      MotivoFila.sobra => (
        Icons.school_rounded,
        'Estudo do dia',
        scheme.secondary,
      ),
    };

    return SafeArea(
      child: Padding(
        key: const Key('painel_relampago'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: 8),
                Text('Questão relâmpago', style: texto.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Chip(
              key: Key('motivo_${relampago.motivo.name}'),
              avatar: Icon(icone, color: cor, size: 18),
              label: Text(rotulo),
              side: BorderSide(color: cor),
            ),
            const SizedBox(height: 12),
            Text(relampago.explicacao, style: texto.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Escolhida pela fila adaptativa: grafo de pré-requisitos, '
              'previsor de esquecimento e nível estimado.',
              style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('botao_responder_relampago'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Responder'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/sessao?questao=${relampago.questao.id}&relampago=1',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
