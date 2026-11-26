import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../ia/montador_fila.dart';
import '../../ia/servico_aprendizado.dart';
import '../../ia/simulador_fila.dart';
import '../../tema/app_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/saude_memoria.dart';

/// Simulação da fila de hoje e da fila de quando um pré-requisito fica
/// crítico. Só calcula: não grava memória nem cria pendência de envio.
final simulacaoFilaProvider = FutureProvider.autoDispose<SimulacaoFila?>((
  ref,
) async {
  ref.watch(versaoAprendizadoProvider);
  final usuario = ref.watch(usuarioProvider);
  if (usuario == null) return null;
  final servico = await ref.watch(servicoAprendizadoProvider.future);
  return servico.simularVirada(
    usuario,
    idMateria: ref.watch(idMateriaSelecionadaProvider),
    idMateriaOculta: ref.watch(idMateriaOcultaProvider),
  );
});

String _porcento(double r) => '${(r * 100).floor()}%';

/// "Por que essa fila?": o antes e o depois da fila quando o modelo de
/// esquecimento prevê que um pré-requisito vai cair para o vermelho.
class FilaExplicadaScreen extends ConsumerStatefulWidget {
  const FilaExplicadaScreen({super.key});

  @override
  ConsumerState<FilaExplicadaScreen> createState() =>
      _FilaExplicadaScreenState();
}

class _FilaExplicadaScreenState extends ConsumerState<FilaExplicadaScreen> {
  bool _depois = false;

  @override
  Widget build(BuildContext context) {
    final simulacao = ref.watch(simulacaoFilaProvider);
    return Scaffold(
      key: const Key('tela_fila_explicada'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Por que essa fila?'),
      ),
      body: simulacao.when(
        loading: () => const Carregando(),
        error: (_, _) => const EstadoVazio(
          titulo: 'Não foi possível simular a fila',
          descricao: 'Tente de novo em instantes.',
        ),
        data: (s) => s == null
            ? const EstadoVazio(
                titulo: 'Ainda não há o que simular',
                descricao:
                    'Responda questões de assuntos que são pré-requisito de '
                    'outros. Quando o modelo previr que um deles vai ser '
                    'esquecido, esta tela mostra como a fila muda.',
              )
            : _conteudo(context, s),
      ),
    );
  }

  Widget _conteudo(BuildContext context, SimulacaoFila s) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final momento = _depois ? s.depois : s.antes;
    final mudancas = s.mudancas;
    // Marca só quantas questões de cada assunto mudam, de trás para frente:
    // de 3 para 2 questões, só uma aparece como "sai".
    final faltam = {
      for (final m in mudancas)
        if (_depois ? m.diferenca > 0 : m.diferenca < 0)
          m.idAssunto: m.diferenca.abs(),
    };
    final marcadas = <int>{};
    for (final (i, item) in momento.itens.indexed.toList().reversed) {
      final resta = faltam[item.questao.idAssunto] ?? 0;
      if (resta == 0) continue;
      marcadas.add(i);
      faltam[item.questao.idAssunto] = resta - 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        _CabecalhoVirada(simulacao: s),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          key: const Key('alternar_momento'),
          segments: [
            const ButtonSegment(
              value: false,
              label: Text('Hoje'),
              icon: Icon(Icons.today_rounded),
            ),
            ButtonSegment(
              value: true,
              label: Text('Daqui a ${s.depois.dias} dias'),
              icon: const Icon(Icons.update_rounded),
            ),
          ],
          selected: {_depois},
          onSelectionChanged: (v) => setState(() => _depois = v.first),
        ),
        const SizedBox(height: 12),
        TituloSecao(
          s.materia == null ? 'Fila do dia' : 'Fila do dia em ${s.materia}',
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_depois),
            children: [
              for (final (i, item) in momento.itens.indexed)
                _LinhaFila(
                  posicao: i + 1,
                  assunto: s.nome(item.questao.idAssunto),
                  motivo: item.motivo,
                  marca: !marcadas.contains(i)
                      ? null
                      : _depois
                      ? _Marca.entra
                      : _Marca.sai,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CartaoMudancas(simulacao: s, mudancas: mudancas),
        const SizedBox(height: 16),
        Text(
          'Simulação: o modelo de esquecimento avança ${s.depois.dias} dias '
          'sem nenhum estudo, o grafo bloqueia o que depende de '
          '${s.prerequisito} e a fila é montada de novo. Nada é gravado.',
          style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// O pré-requisito passando do amarelo (ou verde) para o vermelho.
class _CabecalhoVirada extends StatelessWidget {
  final SimulacaoFila simulacao;
  const _CabecalhoVirada({required this.simulacao});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final s = simulacao;
    final antes = estadoDaRetencao(s.retencaoAntes);
    final depois = estadoDaRetencao(s.retencaoDepois);
    Widget selo(String quando, double r, EstadoMemoria e) => Expanded(
      child: Column(
        children: [
          Text(quando, style: texto.labelMedium),
          const SizedBox(height: 6),
          Text(
            _porcento(r),
            style: texto.headlineMedium?.copyWith(color: corDaMemoria(e)),
          ),
          Text(
            rotuloDaMemoria(e),
            style: texto.labelMedium?.copyWith(color: corDaMemoria(e)),
          ),
        ],
      ),
    );

    return AppCartao(
      key: const Key('cabecalho_virada'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quando ${s.prerequisito} entra no vermelho',
            style: texto.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'É pré-requisito de ${s.dependentes.map(s.nome).join(', ')}.',
            style: texto.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              selo('Hoje', s.retencaoAntes, antes),
              const Icon(Icons.arrow_forward_rounded),
              selo('Daqui a ${s.depois.dias} dias', s.retencaoDepois, depois),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resumo do que entra e do que sai da fila.
class _CartaoMudancas extends StatelessWidget {
  final SimulacaoFila simulacao;
  final List<MudancaFila> mudancas;
  const _CartaoMudancas({required this.simulacao, required this.mudancas});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final s = simulacao;
    final bloqueados = mudancas.where((m) => m.bloqueado).toList();
    final outrasSaidas = mudancas
        .where((m) => m.diferenca < 0 && !m.bloqueado)
        .toList();
    final entradas = mudancas.where((m) => m.diferenca > 0).toList();
    String lista(Iterable<MudancaFila> ms) {
      final nomes = ms.map((m) => m.assunto).toList();
      if (nomes.length == 1) return nomes.first;
      return '${nomes.take(nomes.length - 1).join(', ')} e ${nomes.last}';
    }

    Widget linha(IconData icone, Color cor, String frase, {Key? key}) =>
        Padding(
          key: key,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(frase, style: texto.bodyMedium)),
            ],
          ),
        );

    return AppCartao(
      key: const Key('cartao_mudancas'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('O que muda na fila', style: texto.titleMedium),
          const SizedBox(height: 8),
          if (mudancas.isEmpty)
            Text(
              'Nada muda: a fila de hoje continua valendo.',
              style: texto.bodyMedium,
            ),
          if (bloqueados.isNotEmpty)
            linha(
              Icons.block_rounded,
              CoresMemoria.critico,
              '${bloqueados.length == 1 ? 'Sai' : 'Saem'} ${lista(bloqueados)}: '
              'dependem de ${s.prerequisito}, que entrou no vermelho. '
              'Não adianta avançar sem a base.',
              key: const Key('linha_bloqueados'),
            ),
          for (final motivo in MotivoFila.values)
            if (entradas.any((m) => m.motivo == motivo))
              linha(
                Icons.add_circle_rounded,
                _corDoMotivo(context, motivo),
                'Entra${entradas.where((m) => m.motivo == motivo).length > 1 ? 'm' : ''} '
                '${lista(entradas.where((m) => m.motivo == motivo))} '
                '(${_rotuloDoMotivo(motivo).toLowerCase()}).',
              ),
          if (outrasSaidas.isNotEmpty)
            linha(
              Icons.remove_circle_outline_rounded,
              Theme.of(context).colorScheme.onSurfaceVariant,
              'Para abrir espaço, sai${outrasSaidas.length > 1 ? 'em' : ''} '
              '${lista(outrasSaidas)}.',
            ),
        ],
      ),
    );
  }
}

enum _Marca { entra, sai }

class _LinhaFila extends StatelessWidget {
  final int posicao;
  final String assunto;
  final MotivoFila motivo;
  final _Marca? marca;
  const _LinhaFila({
    required this.posicao,
    required this.assunto,
    required this.motivo,
    required this.marca,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cor = _corDoMotivo(context, motivo);
    final destaque = switch (marca) {
      _Marca.entra => CoresMemoria.consolidado,
      _Marca.sai => CoresMemoria.critico,
      null => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: destaque?.withValues(alpha: 0.10) ?? scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destaque ?? scheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('$posicao', style: texto.labelLarge)),
          Expanded(child: Text(assunto, style: texto.bodyMedium)),
          const SizedBox(width: 8),
          if (marca != null) ...[
            Text(
              marca == _Marca.entra ? 'entra' : 'sai',
              style: texto.labelMedium?.copyWith(color: destaque),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _rotuloDoMotivo(motivo),
              style: texto.labelSmall?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

String _rotuloDoMotivo(MotivoFila? motivo) => switch (motivo) {
  MotivoFila.causaRaiz => 'Causa-raiz',
  MotivoFila.revisao => 'Revisão',
  MotivoFila.nova => 'Nova no nível',
  MotivoFila.sobra || null => 'Completa a fila',
};

Color _corDoMotivo(BuildContext context, MotivoFila? motivo) =>
    switch (motivo) {
      MotivoFila.causaRaiz => CoresMemoria.critico,
      MotivoFila.revisao => CoresMemoria.emRisco,
      MotivoFila.nova => Theme.of(context).colorScheme.primary,
      MotivoFila.sobra ||
      null => Theme.of(context).colorScheme.onSurfaceVariant,
    };
