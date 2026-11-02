import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../../grafo/grafo_conhecimento.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/saude_memoria.dart';

const _larguraVertice = 124.0;
const _alturaVertice = 52.0;
const _espacoX = 22.0;
const _espacoY = 64.0;
const _margem = 24.0;

/// Posição de cada vértice: a linha é a camada do grafo.
class LayoutMapa {
  final Map<int, Rect> vertices;
  final Size tamanho;
  const LayoutMapa(this.vertices, this.tamanho);

  factory LayoutMapa.de(GrafoConhecimento grafo) {
    final linhas = <int, List<int>>{};
    grafo.camadas().forEach((id, camada) {
      (linhas[camada] ??= []).add(id);
    });
    final maiorLinha = linhas.values.fold(
      1,
      (maior, l) => l.length > maior ? l.length : maior,
    );
    final largura =
        maiorLinha * (_larguraVertice + _espacoX) - _espacoX + 2 * _margem;

    final vertices = <int, Rect>{};
    linhas.forEach((camada, ids) {
      final ocupado = ids.length * (_larguraVertice + _espacoX) - _espacoX;
      var x = (largura - ocupado) / 2;
      for (final id in ids) {
        vertices[id] = Rect.fromLTWH(
          x,
          _margem + camada * (_alturaVertice + _espacoY),
          _larguraVertice,
          _alturaVertice,
        );
        x += _larguraVertice + _espacoX;
      }
    });
    final altura =
        linhas.length * (_alturaVertice + _espacoY) - _espacoY + 2 * _margem;
    return LayoutMapa(vertices, Size(largura, altura));
  }

  int? verticeEm(Offset ponto) {
    for (final MapEntry(key: id, value: area) in vertices.entries) {
      if (area.contains(ponto)) return id;
    }
    return null;
  }
}

/// Mapa de conhecimento: o grafo de assuntos colorido pela memória do aluno.
class MapaScreen extends ConsumerWidget {
  const MapaScreen({super.key});

  void _abrirVertice(
    BuildContext context,
    int id,
    Conteudo conteudo,
    GrafoConhecimento grafo,
    Map<int, double> retencoes,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (contexto) => _DetalheVertice(
        assunto: conteudo.assuntoPorId(id)!,
        prerequisitos: [
          for (final p in grafo.prerequisitos(id)) conteudo.nomeDoAssunto(p),
        ],
        retencao: retencoes[id],
        aoEstudar: () {
          Navigator.pop(contexto);
          context.push('/sessao?assunto=$id');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final dependencias = ref.watch(dependenciasProvider).valueOrNull;
    final retencoes = ref.watch(retencoesProvider).valueOrNull ?? const {};
    final idMateria = ref.watch(idMateriaSelecionadaProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget corpo() {
      if (conteudo == null || dependencias == null) return const Carregando();
      final assuntos = idMateria == null
          ? conteudo.assuntos
          : conteudo.assuntosDaMateria(idMateria);
      final ids = assuntos.map((a) => a.id).toSet();
      final grafo = GrafoConhecimento(ids.toList(), [
        for (final d in dependencias)
          if (ids.contains(d.prerequisito) && ids.contains(d.dependente)) d,
      ]);
      final layout = LayoutMapa.de(grafo);

      return InteractiveViewer(
        constrained: false,
        minScale: 0.4,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(120),
        child: GestureDetector(
          key: const Key('mapa_canvas'),
          onTapUp: (detalhes) {
            final id = layout.verticeEm(detalhes.localPosition);
            if (id != null) {
              _abrirVertice(context, id, conteudo, grafo, retencoes);
            }
          },
          child: CustomPaint(
            size: layout.tamanho,
            painter: _PintorMapa(
              layout: layout,
              grafo: grafo,
              nomes: {for (final a in assuntos) a.id: a.nome},
              retencoes: retencoes,
              corTexto: scheme.onSurface,
              corAresta: scheme.onSurfaceVariant,
              fundo: scheme.surface,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: const Key('tela_mapa'),
      appBar: AppBar(
        leading: const BotaoVoltar(),
        title: const Text('Mapa de conhecimento'),
        actions: const [BotaoTema(), SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          Expanded(child: corpo()),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: LegendaMemoria(comNaoEstudado: true),
          ),
        ],
      ),
    );
  }
}

class _PintorMapa extends CustomPainter {
  final LayoutMapa layout;
  final GrafoConhecimento grafo;
  final Map<int, String> nomes;
  final Map<int, double> retencoes;
  final Color corTexto;
  final Color corAresta;
  final Color fundo;

  _PintorMapa({
    required this.layout,
    required this.grafo,
    required this.nomes,
    required this.retencoes,
    required this.corTexto,
    required this.corAresta,
    required this.fundo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final traco = Paint()
      ..color = corAresta.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final ponta = Paint()..color = corAresta.withValues(alpha: 0.75);

    layout.vertices.forEach((id, area) {
      for (final dep in grafo.dependentes(id)) {
        final destino = layout.vertices[dep];
        if (destino != null) _seta(canvas, area, destino, traco, ponta);
      }
    });

    // Os três assuntos de que mais coisas dependem têm a borda mais grossa.
    final gargalos = grafo.gargalos().take(3).toSet();
    layout.vertices.forEach((id, area) {
      _vertice(canvas, id, area, gargalos.contains(id));
    });
  }

  void _seta(Canvas canvas, Rect de, Rect ate, Paint traco, Paint ponta) {
    final inicio = de.bottomCenter;
    final fim = ate.topCenter;
    final meio = (inicio.dy + fim.dy) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(inicio.dx, inicio.dy)
        ..cubicTo(inicio.dx, meio, fim.dx, meio, fim.dx, fim.dy - 6),
      traco,
    );
    canvas.drawPath(
      Path()
        ..moveTo(fim.dx, fim.dy)
        ..lineTo(fim.dx - 5, fim.dy - 8)
        ..lineTo(fim.dx + 5, fim.dy - 8)
        ..close(),
      ponta,
    );
  }

  void _vertice(Canvas canvas, int id, Rect area, bool gargalo) {
    final cor = corDaMemoria(estadoDaRetencao(retencoes[id]));
    final forma = RRect.fromRectAndRadius(area, const Radius.circular(14));
    canvas.drawRRect(forma, Paint()..color = fundo);
    canvas.drawRRect(forma, Paint()..color = cor.withValues(alpha: 0.2));
    canvas.drawRRect(
      forma,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = gargalo ? 3.5 : 2,
    );
    final rotulo = TextPainter(
      text: TextSpan(
        text: nomes[id] ?? '',
        style: TextStyle(
          color: corTexto,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: area.width - 14);
    rotulo.paint(
      canvas,
      area.center - Offset(rotulo.width / 2, rotulo.height / 2),
    );
    rotulo.dispose();
  }

  @override
  bool shouldRepaint(_PintorMapa antigo) =>
      antigo.retencoes != retencoes ||
      antigo.layout != layout ||
      antigo.corTexto != corTexto;
}

class _DetalheVertice extends StatelessWidget {
  final Assunto assunto;
  final List<String> prerequisitos;
  final double? retencao;
  final VoidCallback aoEstudar;

  const _DetalheVertice({
    required this.assunto,
    required this.prerequisitos,
    required this.retencao,
    required this.aoEstudar,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final estado = estadoDaRetencao(retencao);
    final valor = retencao;
    return SafeArea(
      child: Padding(
        key: const Key('detalhe_vertice'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(assunto.nome, style: texto.titleLarge),
            if (assunto.descricao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(assunto.descricao, style: texto.bodyMedium),
            ],
            const SizedBox(height: 14),
            Text(
              valor == null
                  ? 'Retenção: ainda não estudado'
                  : 'Retenção: ${(valor * 100).round()}% '
                        '(${rotuloDaMemoria(estado)})',
              style: texto.titleSmall?.copyWith(color: corDaMemoria(estado)),
            ),
            const SizedBox(height: 8),
            Text(
              prerequisitos.isEmpty
                  ? 'Sem pré-requisitos.'
                  : 'Pré-requisitos: ${prerequisitos.join(', ')}.',
              style: texto.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('botao_estudar_assunto'),
              onPressed: aoEstudar,
              child: const Text('Estudar este assunto'),
            ),
          ],
        ),
      ),
    );
  }
}
