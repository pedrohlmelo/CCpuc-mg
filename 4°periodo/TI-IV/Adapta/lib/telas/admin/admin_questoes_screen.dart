import 'package:flutter/material.dart';

import '../../dados/dados_exemplo.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Banco de questões (RF11). Lista as questões de exemplo com suas
/// alternativas e o gabarito destacado.
class AdminQuestoesScreen extends StatelessWidget {
  const AdminQuestoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Questões',
      subtitulo: 'Cada questão pertence a um assunto',
      rotuloAdicionar: 'Nova questão',
      aoAdicionar: () => avisarPrototipo(context, 'O cadastro de questões'),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: questoesExemplo.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final q = questoesExemplo[i];
          return AppCartao(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _Etiqueta(
                        nomeDoAssunto(q.idAssunto),
                        scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Etiqueta(
                      'Dificuldade ${q.dificuldade}/5',
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
                          '${a.letra}) ${a.texto}',
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
