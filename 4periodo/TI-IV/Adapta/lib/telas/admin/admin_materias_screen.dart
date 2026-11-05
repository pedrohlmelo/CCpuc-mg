import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/paleta_materias.dart';
import '../aluno/materias_screen.dart' show areasDoEnem;
import 'admin_scaffold.dart';

/// Matérias cadastradas (RF11). Grava no aparelho na hora; o envio à nuvem
/// segue sozinho.
class AdminMateriasScreen extends ConsumerStatefulWidget {
  const AdminMateriasScreen({super.key});

  @override
  ConsumerState<AdminMateriasScreen> createState() =>
      _AdminMateriasScreenState();
}

class _AdminMateriasScreenState extends ConsumerState<AdminMateriasScreen> {
  bool _inativos = false;

  AdminConteudoRepositorio get _repo =>
      ref.read(adminConteudoRepositorioProvider);

  Future<void> _nova() async {
    final r = await mostrarDialogoDois(
      context,
      titulo: 'Nova matéria',
      rotuloNome: 'Nome',
      comArea: true,
    );
    if (r == null || !mounted) return;
    await executarAdmin(context, ref, () => _repo.criarMateria(r.$1, r.$2));
  }

  Future<void> _editar(Materia m) async {
    final r = await mostrarDialogoDois(
      context,
      titulo: 'Editar matéria',
      rotuloNome: 'Nome',
      comArea: true,
      nome: m.nome,
      area: m.area,
    );
    if (r == null || !mounted) return;
    await executarAdmin(
      context,
      ref,
      () => _repo.editarMateria(m.id, r.$1, r.$2),
    );
  }

  Future<void> _excluir(Materia m) async {
    final impacto = await _repo.impactoMateria(m.id);
    if (!mounted) return;
    final ok = await confirmarExclusao(
      context,
      'A matéria "${m.nome}"',
      mensagem:
          'A matéria "${m.nome}" sai do app do aluno junto com '
          '${impacto.assuntos} assuntos e ${impacto.questoes} questões, e as '
          'dependências deles são removidas. O histórico continua, e dá para '
          'reativar em "Mostrar inativos".',
    );
    if (!ok || !mounted) return;
    await executarAdmin(context, ref, () => _repo.excluirMateria(m.id));
  }

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final materias = [
      for (final m in conteudo?.todasMaterias ?? const <Materia>[])
        if (m.ativo || _inativos) m,
    ];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Matérias',
      subtitulo: 'Filtro principal do aluno',
      rotuloAdicionar: 'Nova matéria',
      aoAdicionar: _nova,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ChipInativos(
                valor: _inativos,
                aoMudar: (v) => setState(() => _inativos = v),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: materias.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = materias[i];
                final estilo = estiloMateria(m.nome, m.id);
                final area = areasDoEnem
                    .where((a) => a.$1 == m.area)
                    .map((a) => a.$2)
                    .firstOrNull;
                return acinzentar(
                  !m.ativo,
                  AppCartao(
                    key: Key('materia_${m.id}'),
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    aoTocar: m.ativo ? () => _editar(m) : null,
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
                                '${conteudo!.assuntosDaMateria(m.id).length} '
                                'assuntos · ${area ?? m.area}'
                                '${m.ativo ? '' : ' · inativa'}',
                                style: texto.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconePendente(m.pendente),
                        if (m.ativo)
                          IconButton(
                            key: Key('excluir_materia_${m.id}'),
                            tooltip: 'Excluir',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () => _excluir(m),
                          )
                        else
                          TextButton(
                            key: Key('reativar_materia_${m.id}'),
                            onPressed: () => executarAdmin(
                              context,
                              ref,
                              () => _repo.reativarMateria(m.id),
                            ),
                            child: const Text('Reativar'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
