import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Banco de questões (RF11). Lista as questões cadastradas com suas
/// alternativas e o gabarito destacado.
class AdminQuestoesScreen extends ConsumerWidget {
  const AdminQuestoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Questões',
      subtitulo: 'Cada questão pertence a um assunto',
      rotuloAdicionar: 'Nova questão',
      aoAdicionar: () => avisarPrototipo(context, 'O cadastro de questões'),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: conteudo?.questoes.length ?? 0,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final q = conteudo!.questoes[i];
          return AppCartao(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _Etiqueta(
                        conteudo.nomeDoAssunto(q.idAssunto),
                        scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Etiqueta(
                      'Dificuldade ${q.dificuldade}/3',
                      scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(q.enunciado, style: texto.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in q.alternativas)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: a.correta
                              ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                              : scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${a.letra}) ${a.texto ?? a.imagemDescricao ?? 'imagem'}',
                          style: texto.labelMedium?.copyWith(
                            color: a.correta
                                ? const Color(0xFF15803D)
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  const _Etiqueta(this.texto, this.cor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
    ),
  );
}
