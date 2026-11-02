import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/sincronizacao/servico_sincronizacao.dart';
import '../../tema/app_tema.dart';
import '../../tema/tema_controller.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/mascote.dart';
import '../../widgets/rodape_copyright.dart';

/// Perfil do aluno. É daqui que se chega ao login, ao cadastro e ao painel
/// administrativo: o app abre direto no estudo, sem passar por tela de login.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioProvider);
    final entrou = ref.watch(entrouProvider);
    final status = ref.watch(statusSincronizacaoProvider).valueOrNull;
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final lingua = ref.watch(linguaEstrangeiraProvider);
    final versaoBanco = ref.watch(versaoBancoProvider).valueOrNull;
    final escuro = ref.read(temaProvider.notifier).estaEscuro(context);
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('tela_perfil'),
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          CartaoGradiente(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entrou ? usuario!.nome : 'Você ainda não entrou',
                        style: texto.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario?.email ??
                            'Você estuda como visitante. Crie uma conta para '
                                'guardar seu progresso na nuvem.',
                        style: texto.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Mascote(tamanho: 92),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  status.online
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  status.texto(DateTime.now()),
                  key: const Key('status_sincronizacao'),
                  style: texto.bodySmall,
                ),
              ],
            ),
          ],
          if (conteudo != null && versaoBanco != null) ...[
            const SizedBox(height: 8),
            Text(
              'Banco de questões: ${conteudo.questoes.length} questões no '
              'aparelho (versão $versaoBanco)',
              key: const Key('banco_questoes'),
              style: texto.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          const TituloSecao('Conta'),
          AppCartao(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (entrou)
                  _Item(
                    icone: Icons.logout_rounded,
                    cor: scheme.error,
                    titulo: 'Sair da conta',
                    descricao: 'Volta a estudar sem conta',
                    aoTocar: () => ref.read(sessaoProvider.notifier).sair(),
                  )
                else ...[
                  _Item(
                    key: const Key('item_entrar'),
                    icone: Icons.login_rounded,
                    cor: scheme.primary,
                    titulo: 'Entrar',
                    descricao: 'Já tenho conta no Adapta',
                    aoTocar: () => context.push('/login'),
                  ),
                  Divider(height: 1, indent: 72, color: scheme.outline),
                  _Item(
                    icone: Icons.person_add_alt_rounded,
                    cor: AppCores.teal,
                    titulo: 'Criar conta',
                    descricao: 'Guardar meu progresso',
                    aoTocar: () => context.push('/cadastro'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const TituloSecao('Preferências'),
          AppCartao(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Item(
                  icone: escuro
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  cor: AppCores.violeta,
                  titulo: escuro ? 'Tema claro' : 'Tema escuro',
                  descricao: 'Alternar a aparência do app',
                  aoTocar: () =>
                      ref.read(temaProvider.notifier).alternar(context),
                ),
                Divider(height: 1, indent: 72, color: scheme.outline),
                _Item(
                  key: const Key('item_lingua'),
                  icone: Icons.translate_rounded,
                  cor: AppCores.teal,
                  titulo: switch (lingua) {
                    'ingles' => 'Língua estrangeira: Inglês',
                    'espanhol' => 'Língua estrangeira: Espanhol',
                    _ => 'Escolher língua estrangeira',
                  },
                  descricao: 'Toque para trocar entre Inglês e Espanhol',
                  aoTocar: () => ref
                      .read(linguaEstrangeiraProvider.notifier)
                      .escolher(lingua == 'ingles' ? 'espanhol' : 'ingles'),
                ),
                // O painel é de uso interno: para o aluno, esta linha não
                // existe, e a rota /admin também não abre.
                if (usuario?.isAdmin ?? false) ...[
                  Divider(height: 1, indent: 72, color: scheme.outline),
                  _Item(
                    key: const Key('item_admin'),
                    icone: Icons.admin_panel_settings_outlined,
                    cor: scheme.onSurfaceVariant,
                    titulo: 'Painel administrativo',
                    descricao: 'Uso interno do grupo',
                    aoTocar: () => context.push('/admin'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCartao(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sobre o Adapta', style: texto.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'Seu progresso fica neste aparelho e funciona sem internet. '
                  'Com uma conexão, ele é copiado para a nuvem.',
                  style: texto.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const RodapeCopyright(),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;

  const _Item({
    super.key,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    shape: const RoundedRectangleBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: IconeCaixa(icone: icone, cor: cor, tamanho: 40),
    title: Text(titulo),
    subtitle: Text(descricao),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: aoTocar,
  );
}
