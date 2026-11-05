import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../../dados/sincronizacao/servico_sincronizacao.dart';
import '../../tema/app_tema.dart';
import '../../widgets/cartoes.dart';
import 'admin_scaffold.dart';

/// Dependências entre assuntos (RF11): `pré-requisito → dependente`, com a
/// força da dependência. O grafo precisa continuar sendo um DAG.
class AdminGrafoScreen extends ConsumerWidget {
  const AdminGrafoScreen({super.key});

  /// Aresta que fecharia ciclo é recusada, mostrando o caminho que já existe.
  Future<void> _nova(
    BuildContext context,
    WidgetRef ref,
    Conteudo conteudo,
    List<Dependencia> dependencias,
  ) async {
    final aresta = await showDialog<Dependencia>(
      context: context,
      builder: (_) => _DialogoAresta(conteudo: conteudo),
    );
    if (aresta == null || !context.mounted) return;

    try {
      await ref.read(adminConteudoRepositorioProvider).criarAresta(aresta);
    } on ErroAdmin catch (erro) {
      if (!context.mounted) return;
      final caminho = erro.caminho?.map(conteudo.nomeDoAssunto).join(' → ');
      avisar(
        context,
        caminho == null ? erro.mensagem : '${erro.mensagem} $caminho',
        erro: true,
      );
      return;
    }
    if (!context.mounted) return;
    final online = await ref.read(conectividadeProvider).online();
    if (context.mounted) {
      avisar(
        context,
        online
            ? 'Dependência salva.'
            : 'Dependência salva no aparelho; envio à nuvem pendente',
      );
    }
  }

  Future<void> _editarPeso(
    BuildContext context,
    WidgetRef ref,
    Dependencia d,
  ) async {
    final peso = await showDialog<double>(
      context: context,
      builder: (_) => _DialogoPeso(inicial: d.peso),
    );
    if (peso == null || !context.mounted) return;
    await executarAdmin(
      context,
      ref,
      () => ref
          .read(adminConteudoRepositorioProvider)
          .editarPeso(d.prerequisito, d.dependente, peso),
    );
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
          bool pendente(int idAssunto) {
            final a = conteudo!.assuntoPorId(idAssunto);
            return a != null &&
                (conteudo.materiaPorId(a.idMateria)?.pendente ?? false);
          }

          return AppCartao(
            key: Key('aresta_${d.prerequisito}_${d.dependente}'),
            aoTocar: () => _editarPeso(context, ref, d),
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
                IconePendente(
                  pendente(d.prerequisito) || pendente(d.dependente),
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
                      mensagem:
                          'A dependência será removida do grafo. Dá para '
                          'criá-la de novo depois.',
                    );
                    if (!ok || !context.mounted) return;
                    await executarAdmin(
                      context,
                      ref,
                      () => ref
                          .read(adminConteudoRepositorioProvider)
                          .removerAresta(d.prerequisito, d.dependente),
                    );
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
  final Conteudo conteudo;
  const _DialogoAresta({required this.conteudo});

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
        for (final m in widget.conteudo.materias) ...[
          DropdownMenuItem<Assunto>(
            enabled: false,
            child: Text(
              m.nome.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          for (final a in widget.conteudo.assuntosDaMateria(m.id))
            DropdownMenuItem(
              value: a,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(a.nome, overflow: TextOverflow.ellipsis),
              ),
            ),
        ],
      ],
      selectedItemBuilder: (_) => [
        for (final m in widget.conteudo.materias) ...[
          const SizedBox.shrink(),
          for (final a in widget.conteudo.assuntosDaMateria(m.id))
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${a.nome} (${m.nome})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
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

/// Muda a força de uma dependência.
class _DialogoPeso extends StatefulWidget {
  final double inicial;
  const _DialogoPeso({required this.inicial});

  @override
  State<_DialogoPeso> createState() => _DialogoPesoState();
}

class _DialogoPesoState extends State<_DialogoPeso> {
  late double _peso = widget.inicial.clamp(0.1, 1.0);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Força da dependência'),
    content: SizedBox(
      width: 380,
      child: Row(
        children: [
          Expanded(
            child: Slider(
              key: const Key('slider_peso'),
              value: _peso,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              onChanged: (v) => setState(() => _peso = v),
            ),
          ),
          Text(
            _peso.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelLarge,
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
        onPressed: () =>
            Navigator.pop(context, double.parse(_peso.toStringAsFixed(1))),
        child: const Text('Salvar'),
      ),
    ],
  );
}
