import 'package:flutter/material.dart';

import '../../dados/dados_exemplo.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/paleta_materias.dart';
import 'admin_scaffold.dart';

/// Matérias cadastradas (RF11). Lista de exemplo: criar e excluir ainda não
/// gravam nada.
class AdminMateriasScreen extends StatelessWidget {
  const AdminMateriasScreen({super.key});

  Future<void> _nova(BuildContext context) async {
    final nome = await mostrarDialogoTexto(context, 'Nova matéria', 'Nome');
    if (nome == null || nome.trim().isEmpty || !context.mounted) return;
    avisarPrototipo(context, 'O cadastro de matérias');
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Matérias',
      subtitulo: 'Filtro principal do aluno',
      rotuloAdicionar: 'Nova matéria',
      aoAdicionar: () => _nova(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: materiasExemplo.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final m = materiasExemplo[i];
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
                      Text(
                        '${assuntosDaMateria(m.id).length} assuntos',
                        style: texto.bodySmall,
                      ),
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
                    final ok = await confirmarExclusao(
                      context,
                      'A matéria "${m.nome}" e seus assuntos',
                    );
                    if (!ok || !context.mounted) return;
                    avisarPrototipo(context, 'A exclusão de matérias');
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
