import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tema/app_tema.dart';
import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../../../pilares/grafo/grafo_conhecimento.dart';
import '../../materias/data/materia_repository.dart';
import '../../materias/domain/assunto.dart';
import '../data/admin_repository.dart';
import '../data/grafo_repository.dart';
import 'admin_scaffold.dart';

final _arestasProvider = FutureProvider.autoDispose<List<Dependencia>>(
  (ref) => ref.watch(grafoRepositoryProvider).listar(),
);

/// RF11 — arestas do grafo. Rejeita aresta que feche ciclo.
class AdminGrafoScreen extends ConsumerWidget {
  const AdminGrafoScreen({super.key});

  Future<void> _nova(
    BuildContext context,
    WidgetRef ref,
    List<Assunto> assuntos,
  ) async {
    final aresta = await showDialog<Dependencia>(
      context: context,
      builder: (_) => _DialogoAresta(assuntos: assuntos),
    );
    if (aresta == null) return;
    try {
      await ref.read(grafoRepositoryProvider).adicionar(aresta);
      ref.invalidate(_arestasProvider);
      ref.invalidate(resumoAdminProvider);
    } on ArestaCriaCiclo catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: CoresMemoria.critico,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assuntos = ref.watch(assuntosProvider(null));
    final arestas = ref.watch(_arestasProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Grafo de dependências',
      subtitulo: 'Pré-requisito → dependente · deve ser um DAG',
      rotuloAdicionar: 'Nova aresta',
      aoAdicionar: assuntos.hasValue
          ? () => _nova(context, ref, assuntos.requireValue)
          : null,
      child: arestas.when(
        loading: () => const Carregando(),
        error: (e, _) => EstadoVazio(titulo: 'Erro', descricao: '$e'),
        data: (lista) {
          final nomes = {
            for (final a in assuntos.valueOrNull ?? const <Assunto>[])
              a.id: a.nome,
          };
          if (lista.isEmpty) {
            return const EstadoVazio(
              ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 120),
              titulo: 'O grafo está vazio',
              descricao: 'Crie a primeira dependência entre dois assuntos.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = lista[i];
              return AppCartao(
                padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nomes[d.prerequisito] ?? '#${d.prerequisito}',
                                  style: texto.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(
                              nomes[d.dependente] ?? '#${d.dependente}',
                              style: texto.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('força', style: texto.labelSmall),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: d.peso,
                                    minHeight: 6,
                                    color: AppCores.teal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                d.peso.toStringAsFixed(1),
                                style: texto.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        if (!await confirmarExclusao(
                          context,
                          'A dependência',
                        )) {
                          return;
                        }
                        await ref
                            .read(grafoRepositoryProvider)
                            .remover(d.prerequisito, d.dependente);
                        ref.invalidate(_arestasProvider);
                        ref.invalidate(resumoAdminProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DialogoAresta extends StatefulWidget {
  final List<Assunto> assuntos;
  const _DialogoAresta({required this.assuntos});

  @override
  State<_DialogoAresta> createState() => _DialogoArestaState();
}

class _DialogoArestaState extends State<_DialogoAresta> {
  Assunto? _pre;
  Assunto? _dep;
  double _peso = 1.0;

  @override
  Widget build(BuildContext context) {
    DropdownButtonFormField<Assunto> campo(
      String rotulo,
      Assunto? valor,
      void Function(Assunto?) aoMudar,
    ) => DropdownButtonFormField<Assunto>(
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(labelText: rotulo),
      items: [
        for (final a in widget.assuntos)
          DropdownMenuItem(
            value: a,
            child: Text(a.nome, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: aoMudar,
    );

    return AlertDialog(
      title: const Text('Nova dependência'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            campo('Pré-requisito', _pre, (a) => setState(() => _pre = a)),
            const SizedBox(height: 12),
            campo('Dependente', _dep, (a) => setState(() => _dep = a)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Força da dependência',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                Text(
                  _peso.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            Slider(
              value: _peso,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (v) => setState(() => _peso = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: (_pre == null || _dep == null)
              ? null
              : () => Navigator.pop(
                  context,
                  Dependencia(
                    prerequisito: _pre!.id,
                    dependente: _dep!.id,
                    peso: _peso,
                  ),
                ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
