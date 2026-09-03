import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/botao_tema.dart';

/// Moldura comum das telas do painel: AppBar com volta ao menu e FAB opcional.
class AdminScaffold extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;
  final VoidCallback? aoAdicionar;
  final String rotuloAdicionar;

  const AdminScaffold({
    super.key,
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.aoAdicionar,
    this.rotuloAdicionar = 'Novo',
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: texto.titleLarge),
            if (subtitulo != null) Text(subtitulo!, style: texto.bodySmall),
          ],
        ),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: child,
      floatingActionButton: aoAdicionar == null
          ? null
          : FloatingActionButton.extended(
              onPressed: aoAdicionar,
              icon: const Icon(Icons.add_rounded),
              label: Text(rotuloAdicionar),
            ),
    );
  }
}

/// Diálogo simples de um campo de texto.
Future<String?> mostrarDialogoTexto(
  BuildContext context,
  String titulo,
  String rotulo,
) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: rotulo),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

/// Confirmação de exclusão.
Future<bool> confirmarExclusao(BuildContext context, String oQue) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir?'),
      content: Text('$oQue será removido. Essa ação não pode ser desfeita.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            minimumSize: const Size(120, 44),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
