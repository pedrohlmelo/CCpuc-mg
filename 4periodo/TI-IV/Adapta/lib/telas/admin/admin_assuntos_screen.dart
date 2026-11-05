import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
import '../../dados/repositorios/admin_conteudo_repositorio.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/paleta_materias.dart';
import 'admin_scaffold.dart';

/// Assuntos por matéria (RF11). Cada assunto é um vértice do grafo.
class AdminAssuntosScreen extends ConsumerStatefulWidget {
  const AdminAssuntosScreen({super.key});

  @override
  ConsumerState<AdminAssuntosScreen> createState() =>
      _AdminAssuntosScreenState();
}

class _AdminAssuntosScreenState extends ConsumerState<AdminAssuntosScreen> {
  int _idMateria = 1;
  bool _inativos = false;

  AdminConteudoRepositorio get _repo =>
      ref.read(adminConteudoRepositorioProvider);

  Future<void> _novo() async {
    final r = await mostrarDialogoDois(
      context,
      titulo: 'Novo assunto',
      rotuloNome: 'Nome',
      comArea: false,
    );
    if (r == null || !mounted) return;
    await executarAdmin(
      context,
      ref,
      () => _repo.criarAssunto(_idMateria, r.$1, r.$2),
    );
  }

  Future<void> _editar(Assunto a) async {
    final r = await mostrarDialogoDois(
      context,
      titulo: 'Editar assunto',
      rotuloNome: 'Nome',
      comArea: false,
      nome: a.nome,
      descricao: a.descricao,
    );
    if (r == null || !mounted) return;
    await executarAdmin(
      context,
      ref,
      () => _repo.editarAssunto(a.id, r.$1, r.$2),
    );
  }

  Future<void> _excluir(Assunto a) async {
    final impacto = await _repo.impactoAssunto(a.id);
    if (!mounted) return;
    final ok = await confirmarExclusao(
      context,
      'O assunto "${a.nome}"',
      mensagem:
          'O assunto "${a.nome}" sai do app do aluno junto com '
          '${impacto.questoes} questões, e as dependências dele são removidas. '
          'O histórico continua, e dá para reativar em "Mostrar inativos".',
    );
    if (!ok || !mounted) return;
    await executarAdmin(context, ref, () => _repo.excluirAssunto(a.id));
  }

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final materias = [
      for (final m in conteudo?.todasMaterias ?? const <Materia>[])
        if (m.ativo || _inativos) m,
    ];
    final materia = conteudo?.materiaPorId(_idMateria);
    final assuntos = [
      for (final a in conteudo?.todosAssuntos ?? const <Assunto>[])
        if (a.idMateria == _idMateria && (a.ativo || _inativos)) a,
    ];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Assuntos',
      subtitulo: 'Cada assunto é um vértice do grafo',
      rotuloAdicionar: 'Novo assunto',
      aoAdicionar: (materia?.ativo ?? false) ? _novo : null,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: materias.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return ChipInativos(
                    valor: _inativos,
                    aoMudar: (v) => setState(() => _inativos = v),
                  );
                }
                final m = materias[i - 1];
                final estilo = estiloMateria(m.nome, m.id);
                return acinzentar(
                  !m.ativo,
                  ChoiceChip(
                    key: Key('chip_materia_${m.id}'),
                    avatar: Icon(estilo.icone, size: 16, color: estilo.cor),
                    label: Text(m.nome),
                    selected: _idMateria == m.id,
                    onSelected: (_) => setState(() => _idMateria = m.id),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: assuntos.isEmpty
                ? const EstadoVazio(
                    ilustracao: Mascote(pose: PoseCamu.pensativo, tamanho: 120),
                    titulo: 'Nenhum assunto nesta matéria',
                    descricao: 'Toque em "Novo assunto" para criar o primeiro.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: assuntos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final a = assuntos[i];
                      final questoes = conteudo!.questoes
                          .where((q) => q.idAssunto == a.id)
                          .length;
                      return acinzentar(
                        !a.ativo,
                        AppCartao(
                          key: Key('assunto_${a.id}'),
                          aoTocar: a.ativo ? () => _editar(a) : null,
                          padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.nome, style: texto.titleSmall),
                                    Text(
                                      a.ativo
                                          ? '$questoes questões · #${a.id}'
                                          : 'inativo · #${a.id}',
                                      style: texto.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconePendente(materia?.pendente ?? false),
                              if (a.ativo)
                                IconButton(
                                  key: Key('excluir_assunto_${a.id}'),
                                  tooltip: 'Excluir',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _excluir(a),
                                )
                              else if (materia?.ativo ?? false)
                                TextButton(
                                  key: Key('reativar_assunto_${a.id}'),
                                  onPressed: () => executarAdmin(
                                    context,
                                    ref,
                                    () => _repo.reativarAssunto(a.id),
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
