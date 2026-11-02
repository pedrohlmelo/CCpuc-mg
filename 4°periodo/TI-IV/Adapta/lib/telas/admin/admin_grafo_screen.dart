import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../../tema/app_tema.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Dependências entre assuntos (RF11): `pré-requisito → dependente`, com a
/// força da dependência. A validação do grafo (ciclos, DAG) é do backend.
class AdminGrafoScreen extends ConsumerWidget {
  const AdminGrafoScreen({super.key});

  Future<void> _nova(BuildContext context, List<Assunto> assuntos) async {
    final aresta = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoAresta(assuntos: assuntos),
    );
    if (aresta != true || !context.mounted) return;
    avisarPrototipo(context, 'O cadastro de dependências');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final dependencias =
        ref.watch(dependenciasProvider).valueOrNull ?? const [];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Grafo de dependências',
      subtitulo: 'Pré-requisito → dependente',
      rotuloAdicionar: 'Nova aresta',
      aoAdicionar: () => _nova(context, conteudo?.assuntos ?? const []),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: conteudo == null ? 0 : dependencias.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final d = dependencias[i];
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
                              conteudo!.nomeDoAssunto(d.prerequisito),
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
                          conteudo.nomeDoAssunto(d.dependente),
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
                    final ok = await confirmarExclusao(
                      context,
                      'A dependência',
                    );
                    if (!ok || !context.mounted) return;
                    avisarPrototipo(context, 'A exclusão de dependências');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Formulário de nova aresta. Devolve `true` ao confirmar; nada é gravado.
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
              : () => Navigator.pop(context, true),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
