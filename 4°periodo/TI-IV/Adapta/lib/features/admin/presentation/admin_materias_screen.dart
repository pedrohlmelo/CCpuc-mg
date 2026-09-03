import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../../../core/widgets/paleta_materias.dart';
import '../../materias/data/materia_repository.dart';
import '../data/admin_repository.dart';
import 'admin_scaffold.dart';

/// RF11 — matérias.
class AdminMateriasScreen extends ConsumerWidget {
  const AdminMateriasScreen({super.key});

  Future<void> _nova(BuildContext context, WidgetRef ref) async {
    final nome = await mostrarDialogoTexto(context, 'Nova matéria', 'Nome');
    if (nome == null || nome.trim().isEmpty) return;
    await ref.read(materiaRepositoryProvider).criar(nome);
    ref.invalidate(materiasProvider);
    ref.invalidate(resumoAdminProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materias = ref.watch(materiasProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Matérias',
      subtitulo: 'Filtro principal do aluno (RF02)',
      rotuloAdicionar: 'Nova matéria',
      aoAdicionar: () => _nova(context, ref),
      child: materias.when(
        loading: () => const Carregando(),
        error: (e, _) => EstadoVazio(titulo: 'Erro', descricao: '$e'),
        data: (lista) => lista.isEmpty
            ? const EstadoVazio(
                ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 120),
                titulo: 'Nenhuma matéria ainda',
                descricao: 'Toque em "Nova matéria" para começar.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: lista.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final m = lista[i];
                  final estilo = estiloMateria(m.nome, m.id);
                  return AppCartao(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        IconeCaixa(icone: estilo.icone, cor: estilo.cor),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.nome, style: texto.titleMedium),
                              Text('id ${m.id}', style: texto.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () async {
                            if (!await confirmarExclusao(
                              context,
                              'A matéria "${m.nome}" e seus assuntos',
                            )) {
                              return;
                            }
                            await ref
                                .read(materiaRepositoryProvider)
                                .remover(m.id);
                            ref.invalidate(materiasProvider);
                            ref.invalidate(resumoAdminProvider);
                          },
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
