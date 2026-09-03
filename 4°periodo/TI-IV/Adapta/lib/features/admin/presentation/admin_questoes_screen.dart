import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../../materias/data/materia_repository.dart';
import '../../questoes/data/questao_repository.dart';
import '../../questoes/domain/questao.dart';
import 'admin_scaffold.dart';

final _questoesProvider = FutureProvider.autoDispose<List<Questao>>(
  (ref) => ref.watch(questaoRepositoryProvider).listar(),
);

/// RF11 — banco de questões. Nesta sprint só lista; o formulário de cadastro
/// (enunciado + alternativas) fica para a próxima.
class AdminQuestoesScreen extends ConsumerWidget {
  const AdminQuestoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questoes = ref.watch(_questoesProvider);
    final nomes = {
      for (final a in ref.watch(assuntosProvider(null)).valueOrNull ?? const [])
        a.id: a.nome,
    };
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Questões',
      subtitulo: 'Cada questão pertence a um assunto',
      child: questoes.when(
        loading: () => const Carregando(),
        error: (e, _) => EstadoVazio(titulo: 'Erro', descricao: '$e'),
        data: (lista) => lista.isEmpty
            ? const EstadoVazio(
                ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 120),
                titulo: 'Nenhuma questão cadastrada',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final q = lista[i];
                  return AppCartao(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: _Etiqueta(
                                nomes[q.idAssunto] ?? 'Assunto #${q.idAssunto}',
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
                                      ? const Color(
                                          0xFF22C55E,
                                        ).withValues(alpha: 0.12)
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
