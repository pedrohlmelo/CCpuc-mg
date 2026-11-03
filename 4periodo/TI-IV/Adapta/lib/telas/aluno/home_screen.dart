import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../ia/servico_aprendizado.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/marca.dart';
import '../../widgets/mascote.dart';
import '../../widgets/saude_memoria.dart';

/// Tela inicial do aluno e primeira tela do app: o Adapta não abre em login.
///
/// Quem não tem conta estuda como visitante: a tela se apresenta sem nome e
/// convida a criar uma conta para guardar o progresso na nuvem.
const _assuntosNaHome = 5;

Widget _barra(SaudeAssunto s) => BarraSaude(
  nome: s.nome,
  retencao: s.retencao,
  cor: corDaMemoria(s.estado),
  rotulo: rotuloDaMemoria(s.estado),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aluno = ref.watch(usuarioProvider);
    final entrou = ref.watch(entrouProvider);
    final materia = ref.watch(materiaSelecionadaProvider);
    final historico = ref.watch(historicoProvider).valueOrNull ?? const [];
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final respondidas = historico.length;
    final acertos = historico.where((r) => r.acertou).length;
    final taxa = respondidas == 0 ? 0 : (acertos / respondidas * 100).round();
    final panorama = ref.watch(panoramaProvider).valueOrNull ?? Panorama.vazio;
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final oculta = ref.watch(idMateriaOcultaProvider);
    final saude = panorama.saude
        .where((s) => conteudo?.assuntoPorId(s.idAssunto)?.idMateria != oculta)
        .toList();
    final alerta = panorama.alerta;
    final lacuna = panorama.lacuna;

    return Scaffold(
      key: const Key('tela_inicial'),
      appBar: AppBar(
        title: const MarcaAdapta(compacto: true),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entrou ? 'Olá, ${aluno!.primeiroNome}' : 'Vamos estudar?',
                      key: const Key('saudacao'),
                      style: texto.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrou
                          ? 'Pronto para mais um passo?'
                          : 'O Camu monta a sua fila de estudo.',
                      style: texto.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ActionChip(
                      key: const Key('chip_materia'),
                      avatar: Icon(
                        materia == null
                            ? Icons.auto_awesome_rounded
                            : Icons.filter_alt_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      label: Text(materia?.nome ?? 'Estudo guiado'),
                      onPressed: () => context.push('/materias'),
                    ),
                  ],
                ),
              ),
              const MascoteAnimado(tamanho: 96),
            ],
          ),
          const SizedBox(height: 20),
          if (!entrou) ...[const _ConviteEntrar(), const SizedBox(height: 16)],
          if (entrou || respondidas > 0)
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TileEstatistica(
                      valor: '$respondidas',
                      rotulo: 'questões respondidas',
                      icone: Icons.quiz_rounded,
                      cor: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TileEstatistica(
                      valor: '$taxa%',
                      rotulo: 'de acerto',
                      icone: Icons.track_changes_rounded,
                      cor: AppCores.teal,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (lacuna != null) ...[
            _CartaoLacuna(lacuna: lacuna),
            const SizedBox(height: 12),
          ],
          if (alerta != null) ...[
            _AlertaRevisao(alerta: alerta),
            const SizedBox(height: 24),
          ],
          if (saude.isNotEmpty) ...[
            Row(
              children: [
                const Expanded(child: TituloSecao('Saúde da memória')),
              ],
            ),
            AppCartao(
              key: const Key('saude_memoria'),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                children: [
                  for (final s in saude.take(_assuntosNaHome)) _barra(s),
                  if (saude.length > _assuntosNaHome)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('ver_todos_saude'),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(20),
                              children: [for (final s in saude) _barra(s)],
                            ),
                          ),
                        ),
                        child: const Text('Ver todos'),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const LegendaMemoria(),
                ],
              ),
            ),
          ],
          if (respondidas > 0) ...[
            const SizedBox(height: 24),
            const TituloSecao('Seu estudo'),
            AppCartao(
              key: const Key('atalho_historico'),
              padding: const EdgeInsets.all(16),
              aoTocar: () => context.go('/historico'),
              child: Row(
                children: [
                  IconeCaixa(
                    icone: Icons.history_rounded,
                    cor: AppCores.violeta,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Histórico de estudo', style: texto.titleSmall),
                        Text(
                          'Rever questões antigas e suas resoluções.',
                          style: texto.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
          if (aluno?.isAdmin ?? false) ...[
            const SizedBox(height: 24),
            AppCartao(
              key: const Key('atalho_mapa'),
              padding: const EdgeInsets.all(16),
              aoTocar: () => context.push('/mapa'),
              child: Row(
                children: [
                  const IconeCaixa(
                    icone: Icons.account_tree_rounded,
                    cor: AppCores.violeta,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mapa de conhecimento', style: texto.titleSmall),
                        Text(
                          'Seu grafo de assuntos colorido pela memória.',
                          style: texto.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Convite para o visitante criar uma conta.
class _ConviteEntrar extends StatelessWidget {
  const _ConviteEntrar();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return CartaoGradiente(
      key: const Key('convite_entrar'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guarde o seu progresso',
            style: texto.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Você já pode estudar. Com uma conta, seu progresso fica salvo na '
            'nuvem e acompanha você.',
            style: texto.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                key: const Key('botao_entrar_home'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppCores.indigo,
                  minimumSize: const Size(120, 44),
                ),
                onPressed: () => context.push('/login'),
                child: const Text('Entrar'),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.push('/cadastro'),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pré-requisito fraco por trás dos erros, achado no grafo.
class _CartaoLacuna extends StatelessWidget {
  final AvisoLacuna lacuna;
  const _CartaoLacuna({required this.lacuna});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return AppCartao(
      key: const Key('card_lacuna'),
      cor: AppCores.violeta.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconeCaixa(icone: Icons.hub_rounded, cor: AppCores.violeta),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Seus erros em ${lacuna.assunto} apontam para uma lacuna em '
              '${lacuna.raiz}.',
              style: texto.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de assunto prestes a ser esquecido, vindo do modelo.
class _AlertaRevisao extends StatelessWidget {
  final AlertaEsquecimento alerta;
  const _AlertaRevisao({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final assunto = alerta.assunto;
    final critico = assunto.estado == EstadoMemoria.critico;
    final cor = corDaMemoria(assunto.estado);

    return AppCartao(
      cor: cor.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconeCaixa(
            icone: critico
                ? Icons.warning_amber_rounded
                : Icons.schedule_rounded,
            cor: cor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  critico ? 'Revise hoje' : 'Revisão recomendada',
                  style: texto.titleSmall?.copyWith(color: cor),
                ),
                const SizedBox(height: 2),
                Text(
                  'Você tem ${alerta.chance}% de chance de esquecer '
                  '${assunto.nome} amanhã.',
                  style: texto.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
