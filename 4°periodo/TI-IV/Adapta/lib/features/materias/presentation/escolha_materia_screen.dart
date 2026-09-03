import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/botao_tema.dart';
import '../../../core/widgets/cartoes.dart';
import '../../../core/widgets/marca.dart';
import '../../../core/widgets/mascote.dart';
import '../../../core/widgets/paleta_materias.dart';
import '../../autenticacao/application/sessao_controller.dart';
import '../data/materia_repository.dart';
import '../domain/materia.dart';

/// RF02 — escolha da matéria (ou estudo guiado geral).
class EscolhaMateriaScreen extends ConsumerWidget {
  const EscolhaMateriaScreen({super.key});

  void _escolher(BuildContext context, WidgetRef ref, Materia? materia) {
    ref.read(materiaSelecionadaProvider.notifier).state = materia;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materias = ref.watch(materiasProvider);
    final usuario = ref.watch(sessaoProvider);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const MarcaAdapta(compacto: true),
        actions: [
          const BotaoTema(),
          if (usuario?.isAdmin ?? false)
            IconButton(
              tooltip: 'Painel administrativo',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.go('/admin'),
            ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(sessaoProvider.notifier).sair(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: materias.when(
        loading: () => const Carregando(),
        error: (e, _) => EstadoVazio(
          titulo: 'Não consegui carregar as matérias',
          descricao: '$e',
        ),
        data: (lista) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'O que vamos estudar${usuario == null ? '' : ', ${usuario.nome.split(' ').first}'}?',
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
            const TituloSecao('Ou filtre por matéria'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 128,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final m = lista[i];
                final estilo = estiloMateria(m.nome, m.id);
                return AppCartao(
                  key: Key('opcao_materia_${m.id}'),
                  aoTocar: () => _escolher(context, ref, m),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconeCaixa(icone: estilo.icone, cor: estilo.cor),
                      const Spacer(),
                      Text(
                        m.nome,
                        style: texto.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
