import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/paleta_materias.dart';

/// Áreas do ENEM, na ordem da prova.
const areasDoEnem = [
  ('linguagens', 'Linguagens e Códigos'),
  ('humanas', 'Ciências Humanas'),
  ('natureza', 'Ciências da Natureza'),
  ('matematica', 'Matemática'),
];

/// Escolha da matéria, ou estudo guiado com todas. Abre por cima da tela
/// inicial e volta para ela com o filtro aplicado.
class MateriasScreen extends ConsumerWidget {
  const MateriasScreen({super.key});

  void _escolher(BuildContext context, WidgetRef ref, Materia? materia) {
    ref.read(idMateriaSelecionadaProvider.notifier).selecionar(materia);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entrou = ref.watch(entrouProvider);
    final aluno = ref.watch(usuarioProvider);
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final selecionada = ref.watch(materiaSelecionadaProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('tela_materias'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Escolher matéria'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            entrou
                ? 'O que vamos estudar, ${aluno!.primeiroNome}?'
                : 'O que vamos estudar?',
            style: texto.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha uma matéria ou deixe o Camu decidir por você.',
            style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          CartaoGradiente(
            key: const Key('opcao_estudo_geral'),
            aoTocar: () => _escolher(context, ref, null),
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'RECOMENDADO',
                          style: texto.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estudo guiado',
                        style: texto.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fila montada com o que você mais precisa agora.',
                        style: texto.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            'Começar',
                            style: texto.labelLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Mascote(pose: PoseCamu.feliz, tamanho: 104),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (ref.watch(linguaEstrangeiraProvider) == null) ...[
            const _EscolhaLingua(),
            const SizedBox(height: 24),
          ],
          for (final (area, nome) in areasDoEnem) ...[
            TituloSecao(nome),
            GridView.count(
              key: Key('area_$area'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                for (final m in conteudo?.materias ?? const <Materia>[])
                  if (m.area == area)
                    _CartaoMateria(
                      materia: m,
                      assuntos: conteudo!.assuntosDaMateria(m.id).length,
                      ativa: selecionada?.id == m.id,
                      aoTocar: () => _escolher(context, ref, m),
                    ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _CartaoMateria extends StatelessWidget {
  final Materia materia;
  final int assuntos;
  final bool ativa;
  final VoidCallback aoTocar;

  const _CartaoMateria({
    required this.materia,
    required this.assuntos,
    required this.ativa,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final estilo = estiloMateria(materia.nome, materia.id);
    return AppCartao(
      key: Key('opcao_materia_${materia.id}'),
      aoTocar: aoTocar,
      padding: const EdgeInsets.all(16),
      cor: ativa ? estilo.cor.withValues(alpha: 0.10) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeCaixa(icone: estilo.icone, cor: estilo.cor),
          const Spacer(),
          Text(
            materia.nome,
            style: texto.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('$assuntos assuntos', style: texto.bodySmall),
        ],
      ),
    );
  }
}

/// Aparece até o aluno escolher; depois, a troca fica no Perfil.
class _EscolhaLingua extends ConsumerWidget {
  const _EscolhaLingua();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final lingua = ref.read(linguaEstrangeiraProvider.notifier);
    return AppCartao(
      key: const Key('escolha_lingua'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Qual língua você fará no ENEM?', style: texto.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('escolher_ingles'),
                  onPressed: () => lingua.escolher('ingles'),
                  child: const Text('Inglês'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  key: const Key('escolher_espanhol'),
                  onPressed: () => lingua.escolher('espanhol'),
                  child: const Text('Espanhol'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
