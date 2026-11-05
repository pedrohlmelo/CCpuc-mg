import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/sincronizacao/servico_sincronizacao.dart';
import '../aluno/materias_screen.dart' show areasDoEnem;

import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';

/// Moldura comum das telas do painel: título, botão de voltar ao menu do
/// painel e um botão de ação opcional.
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
      key: const Key('tela_admin_interna'),
      appBar: AppBar(
        leading: const BotaoVoltar(rotaDeFallback: '/admin'),
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

void avisar(BuildContext context, String texto, {bool erro = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(texto),
      behavior: SnackBarBehavior.floating,
      backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

/// Roda uma gravação do admin. O SQLite já terminou quando o aviso aparece; o
/// envio à nuvem segue sozinho, então só se diz se ele vai sair agora.
/// Devolve `false` se a gravação foi recusada.
Future<bool> executarAdmin(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() acao,
) async {
  try {
    await acao();
  } on ErroAdmin catch (erro) {
    if (context.mounted) avisar(context, erro.mensagem, erro: true);
    return false;
  }
  final online = await ref.read(conectividadeProvider).online();
  if (context.mounted) {
    avisar(
      context,
      online ? 'Salvo' : 'Salvo no aparelho; envio à nuvem pendente',
    );
  }
  return true;
}

/// Nuvem riscada: a mudança ainda não subiu. Não bloqueia nada.
class IconePendente extends StatelessWidget {
  final bool pendente;
  const IconePendente(this.pendente, {super.key});

  @override
  Widget build(BuildContext context) => !pendente
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Tooltip(
            message: 'Envio à nuvem pendente',
            child: Icon(
              Icons.cloud_off_rounded,
              key: const Key('icone_pendente'),
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
}

/// Chip "Mostrar inativos" das listas do painel.
class ChipInativos extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> aoMudar;
  const ChipInativos({super.key, required this.valor, required this.aoMudar});

  @override
  Widget build(BuildContext context) => FilterChip(
    key: const Key('chip_inativos'),
    label: const Text('Mostrar inativos'),
    selected: valor,
    onSelected: aoMudar,
  );
}

/// Item inativo aparece acinzentado.
Widget acinzentar(bool inativo, Widget child) =>
    inativo ? Opacity(opacity: 0.45, child: child) : child;

/// Diálogo de nome e descrição (assunto) ou nome e área (matéria).
Future<(String, String)?> mostrarDialogoDois(
  BuildContext context, {
  required String titulo,
  required String rotuloNome,
  required bool comArea,
  String nome = '',
  String descricao = '',
  String? area,
}) {
  final cNome = TextEditingController(text: nome);
  final cDescricao = TextEditingController(text: descricao);
  var areaAtual = area;
  return showDialog<(String, String)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('campo_nome'),
                controller: cNome,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: rotuloNome),
              ),
              const SizedBox(height: 12),
              if (comArea)
                DropdownButtonFormField<String>(
                  key: const Key('campo_area'),
                  initialValue: areaAtual,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Área'),
                  items: [
                    for (final (id, nome) in areasDoEnem)
                      DropdownMenuItem(value: id, child: Text(nome)),
                  ],
                  onChanged: (v) => setState(() => areaAtual = v),
                )
              else
                TextField(
                  key: const Key('campo_descricao'),
                  controller: cDescricao,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
            onPressed: () => Navigator.pop(ctx, (
              cNome.text,
              comArea ? (areaAtual ?? '') : cDescricao.text,
            )),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
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

/// Confirmação de exclusão. [mensagem] diz o que sai junto.
Future<bool> confirmarExclusao(
  BuildContext context,
  String oQue, {
  String? mensagem,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Excluir?'),
      content: Text(
        mensagem ??
            '$oQue sai do app do aluno. O histórico continua, e dá para '
                'reativar em "Mostrar inativos".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar_exclusao'),
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
