import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/modelos.dart';
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

  Future<void> _novo() async {
    final nome = await mostrarDialogoTexto(context, 'Novo assunto', 'Nome');
    if (nome == null || nome.trim().isEmpty || !mounted) return;
    avisarPrototipo(context, 'O cadastro de assuntos');
  }

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final materias = conteudo?.materias ?? const <Materia>[];
    final assuntos = conteudo?.assuntosDaMateria(_idMateria) ?? const [];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      titulo: 'Assuntos',
      subtitulo: 'Cada assunto é um vértice do grafo',
      rotuloAdicionar: 'Novo assunto',
      aoAdicionar: _novo,
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: materias.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = materias[i];
                final estilo = estiloMateria(m.nome, m.id);
                return ChoiceChip(
                  key: Key('chip_materia_${m.id}'),
                  avatar: Icon(estilo.icone, size: 16, color: estilo.cor),
                  label: Text(m.nome),
                  selected: _idMateria == m.id,
                  onSelected: (_) => setState(() => _idMateria = m.id),
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
                                    '$questoes questões',
                                    style: texto.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text('#${a.id}', style: texto.labelSmall),
                          ],
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
