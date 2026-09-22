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
import '../../widgets/paleta_materias.dart';

/// Escolha da matéria, ou estudo guiado com todas. Abre por cima da tela
/// inicial e volta para ela com o filtro aplicado.
class MateriasScreen extends ConsumerWidget {
  const MateriasScreen({super.key});

  void _escolher(BuildContext context, WidgetRef ref, Materia? materia) {
    ref.read(materiaSelecionadaProvider.notifier).state = materia;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aluno = ref.watch(usuarioProvider);
    final selecionada = ref.watch(materiaSelecionadaProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('tela_materias'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Escolher matéria'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            aluno == null
                ? 'O que vamos estudar?'
                : 'O que vamos estudar, ${aluno.primeiroNome}?',
            style: texto.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha uma matéria ou deixe o Camu decidir por você.',
            style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          CartaoGradiente(
            key: const Key('opcao_estudo_geral'),
            aoTocar: () => _escolher(context, ref, null),
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
                          'RECOMENDADO',
                          style: texto.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estudo guiado',
                        style: texto.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fila montada com o que você mais precisa agora.',
                        style: texto.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Começar',
                            style: texto.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Mascote(pose: PoseCamu.feliz, tamanho: 104),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const TituloSecao('Ou filtre por matéria'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 140,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: materiasExemplo.length,
            itemBuilder: (_, i) {
              final m = materiasExemplo[i];
              final estilo = estiloMateria(m.nome, m.id);
              final ativa = selecionada?.id == m.id;
              return AppCartao(
                key: Key('opcao_materia_${m.id}'),
                aoTocar: () => _escolher(context, ref, m),
                padding: const EdgeInsets.all(16),
                cor: ativa ? estilo.cor.withValues(alpha: 0.10) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconeCaixa(icone: estilo.icone, cor: estilo.cor),
                    const Spacer(),
                    Text(
                      m.nome,
                      style: texto.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${assuntosDaMateria(m.id).length} assuntos',
                      style: texto.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
