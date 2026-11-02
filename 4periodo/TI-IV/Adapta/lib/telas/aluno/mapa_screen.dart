import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dados/estado_app.dart';
import '../../dados/modelos.dart';
import '../../dados/repositorios/conteudo_repositorio.dart';
import '../../dados/repositorios/grafo_repositorio.dart';
import '../../grafo/grafo_conhecimento.dart';
import '../../ia/servico_aprendizado.dart';
import '../../widgets/botao_tema.dart';
import '../../widgets/botao_voltar.dart';
import '../../widgets/cartoes.dart';
import '../../widgets/saude_memoria.dart';

const _larguraVertice = 124.0;
const _alturaVertice = 52.0;
const _espacoX = 22.0;
const _espacoY = 64.0;
const _margem = 24.0;
const _alturaTitulo = 28.0;

/// Valor do chip "Todas" do mapa.
const _todas = 0;
const _idMatematica = 1;

/// Posição de cada vértice: a linha é a camada do grafo.
class LayoutMapa {
  final Map<int, Rect> vertices;
  final Size tamanho;

  /// Nome de cada grupo e onde ele é escrito, no mapa com todas as matérias.
  final Map<String, Offset> titulos;
  const LayoutMapa(this.vertices, this.tamanho, [this.titulos = const {}]);

  /// Um bloco por matéria, um embaixo do outro.
  factory LayoutMapa.agrupado(List<(String, GrafoConhecimento)> grupos) {
    final vertices = <int, Rect>{};
    final titulos = <String, Offset>{};
    var y = 0.0;
    var largura = 0.0;
    for (final (nome, grafo) in grupos) {
      titulos[nome] = Offset(_margem, y + _margem);
      y += _alturaTitulo;
      final bloco = LayoutMapa.de(grafo);
      bloco.vertices.forEach((id, area) {
        vertices[id] = area.shift(Offset(0, y));
      });
      y += bloco.tamanho.height;
      if (bloco.tamanho.width > largura) largura = bloco.tamanho.width;
    }
    return LayoutMapa(vertices, Size(largura, y), titulos);
  }

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
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  /// Nulo até o aluno tocar num chip: vale a matéria selecionada.
  int? _chip;

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
          for (final p in grafo.prerequisitos(id))
            _comMateria(conteudo, p, conteudo.assuntoPorId(id)!.idMateria),
        ],
        retencao: retencoes[id],
        aoEstudar: () {
          Navigator.pop(contexto);
          context.push('/sessao?assunto=$id');
        },
      ),
    );
  }

  /// Pré-requisito de outra matéria vem com o nome dela.
  String _comMateria(Conteudo conteudo, int idAssunto, int idMateria) {
    final nome = conteudo.nomeDoAssunto(idAssunto);
    final outra = conteudo.assuntoPorId(idAssunto)?.idMateria;
    if (outra == null || outra == idMateria) return nome;
    return '$nome (${conteudo.materiaPorId(outra)?.nome})';
  }

  GrafoConhecimento _grafoDe(
    Iterable<int> ids,
    List<Dependencia> dependencias,
  ) {
    final conjunto = ids.toSet();
    return GrafoConhecimento(conjunto.toList(), [
      for (final d in dependencias)
        if (conjunto.contains(d.prerequisito) &&
            conjunto.contains(d.dependente))
          d,
    ]);
  }

  Widget _chips(Conteudo conteudo, int atual, int? oculta) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            for (final (id, nome) in [
              (_todas, 'Todas'),
              for (final m in conteudo.materias)
                if (m.id != oculta) (m.id, m.nome),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('chip_mapa_$id'),
                  label: Text(nome),
                  selected: id == atual,
                  onSelected: (_) => setState(() => _chip = id),
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoProvider).valueOrNull;
    final dependencias = ref.watch(dependenciasProvider).valueOrNull;
    final retencoes = ref.watch(retencoesProvider).valueOrNull ?? const {};
    final oculta = ref.watch(idMateriaOcultaProvider);
    final chip =
        _chip ?? ref.watch(idMateriaSelecionadaProvider) ?? _idMatematica;
    final scheme = Theme.of(context).colorScheme;

    Widget corpo() {
      if (conteudo == null || dependencias == null) return const Carregando();
      final materias = [
        for (final m in conteudo.materias)
          if (chip == _todas ? m.id != oculta : m.id == chip) m,
      ];
      final assuntos = [
        for (final m in materias) ...conteudo.assuntosDaMateria(m.id),
      ];
      final grafo = _grafoDe(assuntos.map((a) => a.id), dependencias);
      final completo = _grafoDe(
        conteudo.assuntos.map((a) => a.id),
        dependencias,
      );
      final layout = chip == _todas
          ? LayoutMapa.agrupado([
              for (final m in materias)
                (
                  m.nome,
                  _grafoDe(
                    conteudo.assuntosDaMateria(m.id).map((a) => a.id),
                    dependencias,
                  ),
                ),
            ])
          : LayoutMapa.de(grafo);

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
              _abrirVertice(context, id, conteudo, completo, retencoes);
            }
          },
          child: CustomPaint(
            size: layout.tamanho,
            painter: _PintorMapa(
              layout: layout,
              grafo: grafo,
              nomes: {for (final a in assuntos) a.id: a.nome},
              materiaDoAssunto: {for (final a in assuntos) a.id: a.idMateria},
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
          if (conteudo != null) _chips(conteudo, chip, oculta),
          Expanded(child: corpo()),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: LegendaMemoria(comNaoEstudado: true),
            ),
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
  final Map<int, int> materiaDoAssunto;
  final Map<int, double> retencoes;
  final Color corTexto;
  final Color corAresta;
  final Color fundo;

  _PintorMapa({
    required this.layout,
    required this.grafo,
    required this.nomes,
    required this.materiaDoAssunto,
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
        if (destino == null) continue;
        final tracejada = materiaDoAssunto[id] != materiaDoAssunto[dep];
        _seta(canvas, area, destino, traco, ponta, tracejada);
      }
    });
    layout.titulos.forEach((nome, posicao) => _titulo(canvas, nome, posicao));

    // Os três assuntos de que mais coisas dependem têm a borda mais grossa.
    final gargalos = grafo.gargalos().take(3).toSet();
    layout.vertices.forEach((id, area) {
      _vertice(canvas, id, area, gargalos.contains(id));
    });
  }

  void _titulo(Canvas canvas, String nome, Offset posicao) {
    final rotulo = TextPainter(
      text: TextSpan(
        text: nome,
        style: TextStyle(
          color: corTexto,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rotulo.paint(canvas, posicao);
    rotulo.dispose();
  }

  /// Só a parte visível de cada trecho de [caminho].
  Path _tracejado(Path caminho) {
    const traco = 6.0;
    const vao = 5.0;
    final resultado = Path();
    for (final metrica in caminho.computeMetrics()) {
      for (var d = 0.0; d < metrica.length; d += traco + vao) {
        resultado.addPath(metrica.extractPath(d, d + traco), Offset.zero);
      }
    }
    return resultado;
  }

  void _seta(
    Canvas canvas,
    Rect de,
    Rect ate,
    Paint traco,
    Paint ponta,
    bool tracejada,
  ) {
    final inicio = de.bottomCenter;
    final fim = ate.topCenter;
    final meio = (inicio.dy + fim.dy) / 2;
    final curva = Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..cubicTo(inicio.dx, meio, fim.dx, meio, fim.dx, fim.dy - 6);
    canvas.drawPath(tracejada ? _tracejado(curva) : curva, traco);
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
