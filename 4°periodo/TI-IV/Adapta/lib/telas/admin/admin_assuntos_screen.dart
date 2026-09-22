import 'package:flutter/material.dart';

import '../../dados/dados_exemplo.dart';
import '../../dados/modelos.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/paleta_materias.dart';
import 'admin_scaffold.dart';

/// Assuntos por matéria (RF11). Cada assunto é um vértice do grafo.
class AdminAssuntosScreen extends StatefulWidget {
  const AdminAssuntosScreen({super.key});

  @override
  State<AdminAssuntosScreen> createState() => _AdminAssuntosScreenState();
}

class _AdminAssuntosScreenState extends State<AdminAssuntosScreen> {
  Materia _materia = materiasExemplo.first;

  Future<void> _novo() async {
    final nome = await mostrarDialogoTexto(context, 'Novo assunto', 'Nome');
    if (nome == null || nome.trim().isEmpty || !mounted) return;
    avisarPrototipo(context, 'O cadastro de assuntos');
  }

  @override
  Widget build(BuildContext context) {
    final assuntos = assuntosDaMateria(_materia.id);
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
              itemCount: materiasExemplo.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = materiasExemplo[i];
                final estilo = estiloMateria(m.nome, m.id);
                return ChoiceChip(
                  key: Key('chip_materia_${m.id}'),
                  avatar: Icon(estilo.icone, size: 16, color: estilo.cor),
                  label: Text(m.nome),
                  selected: _materia.id == m.id,
                  onSelected: (_) => setState(() => _materia = m),
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
                      final questoes = questoesExemplo
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
