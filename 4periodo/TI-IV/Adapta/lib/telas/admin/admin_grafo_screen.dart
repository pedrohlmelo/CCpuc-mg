import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../../tema/app_tema.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Dependências entre assuntos (RF11): `pré-requisito → dependente`, com a
/// força da dependência. O grafo precisa continuar sendo um DAG.
class AdminGrafoScreen extends ConsumerWidget {
  const AdminGrafoScreen({super.key});

  void _avisar(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  /// Aresta que fecharia ciclo é recusada, mostrando o caminho que já existe.
  Future<void> _nova(
    BuildContext context,
    WidgetRef ref,
    Conteudo conteudo,
    List<Dependencia> dependencias,
  ) async {
    final aresta = await showDialog<Dependencia>(
      context: context,
      builder: (_) => _DialogoAresta(assuntos: conteudo.assuntos),
    );
    if (aresta == null || !context.mounted) return;

    try {
      await ref.read(adminConteudoRepositorioProvider).criarAresta(aresta);
    } on ErroAdmin catch (erro) {
      if (!context.mounted) return;
      final caminho = erro.caminho?.map(conteudo.nomeDoAssunto).join(' → ');
      _avisar(
        context,
        caminho == null ? erro.mensagem : '${erro.mensagem} $caminho',
      );
      return;
    }
    if (context.mounted) _avisar(context, 'Dependência salva.');
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
      aoAdicionar: conteudo == null
          ? null
          : () => _nova(context, ref, conteudo, dependencias),
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
                    await ref
                        .read(adminConteudoRepositorioProvider)
                        .removerAresta(d.prerequisito, d.dependente);
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

/// Formulário de nova aresta. Devolve a aresta ao confirmar.
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
