import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/mascote.dart';
import '../../../core/widgets/paleta_materias.dart';
import '../../materias/data/materia_repository.dart';
import '../../materias/domain/materia.dart';
import '../data/admin_repository.dart';
import 'admin_scaffold.dart';

/// RF11 — assuntos (vértices do grafo), filtrados por matéria.
class AdminAssuntosScreen extends ConsumerStatefulWidget {
  const AdminAssuntosScreen({super.key});

  @override
  ConsumerState<AdminAssuntosScreen> createState() =>
      _AdminAssuntosScreenState();
}

class _AdminAssuntosScreenState extends ConsumerState<AdminAssuntosScreen> {
  Materia? _materia;

  Future<void> _novo() async {
    final materia = _materia;
    if (materia == null) return;
    final nome = await mostrarDialogoTexto(context, 'Novo assunto', 'Nome');
    if (nome == null || nome.trim().isEmpty) return;
    await ref
        .read(materiaRepositoryProvider)
        .criarAssunto(idMateria: materia.id, nome: nome);
    ref.invalidate(assuntosProvider(materia.id));
    ref.invalidate(resumoAdminProvider);
  }

  @override
  Widget build(BuildContext context) {
    final materias = ref.watch(materiasProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Assuntos',
      subtitulo: 'Cada assunto é um vértice do grafo',
      rotuloAdicionar: 'Novo assunto',
      aoAdicionar: _materia == null ? null : _novo,
      child: materias.when(
        loading: () => const Carregando(),
        error: (e, _) => EstadoVazio(titulo: 'Erro', descricao: '$e'),
        data: (lista) {
          _materia ??= lista.isEmpty ? null : lista.first;
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = lista[i];
                    final estilo = estiloMateria(m.nome, m.id);
                    return ChoiceChip(
                      avatar: Icon(estilo.icone, size: 16, color: estilo.cor),
                      label: Text(m.nome),
                      selected: _materia?.id == m.id,
                      onSelected: (_) => setState(() => _materia = m),
                    );
                  },
                ),
              ),
              Expanded(
                child: _materia == null
                    ? const EstadoVazio(
                        ilustracao: Mascote(
                          pose: PoseCamu.pensativo,
                          tamanho: 120,
                        ),
                        titulo: 'Cadastre uma matéria primeiro',
                      )
                    : ref
                          .watch(assuntosProvider(_materia!.id))
                          .when(
                            loading: () => const Carregando(),
                            error: (e, _) =>
                                EstadoVazio(titulo: 'Erro', descricao: '$e'),
                            data: (assuntos) => assuntos.isEmpty
                                ? const EstadoVazio(
                                    ilustracao: Mascote(
                                      pose: PoseCamu.pensativo,
                                      tamanho: 120,
                                    ),
                                    titulo: 'Nenhum assunto nesta matéria',
                                    descricao:
                                        'Toque em "Novo assunto" para criar o primeiro vértice.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      100,
                                    ),
                                    itemCount: assuntos.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) {
                                      final a = assuntos[i];
                                      return AppCartao(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
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
                                                    color: scheme.primary
                                                        .withValues(
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
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    a.nome,
                                                    style: texto.titleSmall,
                                                  ),
                                                  if (a.descricao != null)
                                                    Text(
                                                      a.descricao!,
                                                      style: texto.bodySmall,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '#${a.id}',
                                              style: texto.labelSmall,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
