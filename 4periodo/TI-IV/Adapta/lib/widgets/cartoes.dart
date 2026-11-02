import 'package:flutter/material.dart';

import '../tema/app_tema.dart';

/// Cartão padrão com borda fina e cantos generosos.
class AppCartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? aoTocar;
  final Color? cor;
  final bool destaque;

  const AppCartao({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.aoTocar,
    this.cor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppMedidas.raioCartao),
      side: BorderSide(color: scheme.outline),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: forma,
        shadows: destaque ? sombraSuave(context) : null,
      ),
      child: Material(
        color: cor ?? scheme.surface,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Cartão com gradiente da marca (herói de tela).
class CartaoGradiente extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? aoTocar;
  final Gradient gradiente;

  const CartaoGradiente({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.aoTocar,
    this.gradiente = AppCores.gradienteMarca,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradiente,
        borderRadius: BorderRadius.circular(24),
        boxShadow: sombraSuave(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aoTocar,
          splashColor: Colors.white24,
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: _Bolha(120, Colors.white.withValues(alpha: 0.08)),
              ),
              Positioned(
                right: 40,
                bottom: -50,
                child: _Bolha(140, Colors.white.withValues(alpha: 0.06)),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bolha extends StatelessWidget {
  final double tamanho;
  final Color cor;
  const _Bolha(this.tamanho, this.cor);

  @override
  Widget build(BuildContext context) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
  );
}

/// Ícone dentro de um quadrado colorido suave.
class IconeCaixa extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final double tamanho;

  const IconeCaixa({
    super.key,
    required this.icone,
    required this.cor,
    this.tamanho = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(tamanho * 0.32),
      ),
      child: Icon(icone, color: cor, size: tamanho * 0.5),
    );
  }
}

/// Tile de estatística: número grande + rótulo.
class TileEstatistica extends StatelessWidget {
  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  const TileEstatistica({
    super.key,
    required this.valor,
    required this.rotulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return AppCartao(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconeCaixa(icone: icone, cor: cor, tamanho: 34),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: texto.headlineSmall),
          ),
          Text(
            rotulo,
            style: texto.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Título de seção com ação opcional à direita.
class TituloSecao extends StatelessWidget {
  final String titulo;
  final String? acao;
  final VoidCallback? aoTocarAcao;

  const TituloSecao(this.titulo, {super.key, this.acao, this.aoTocarAcao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (acao != null)
            TextButton(onPressed: aoTocarAcao, child: Text(acao!)),
        ],
      ),
    );
  }
}

/// Estado vazio com mascote.
class EstadoVazio extends StatelessWidget {
  final String titulo;
  final String? descricao;
  final Widget? acao;
  final Widget? ilustracao;

  const EstadoVazio({
    super.key,
    required this.titulo,
    this.descricao,
    this.acao,
    this.ilustracao,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ilustracao != null) ...[
              ilustracao!,
              const SizedBox(height: 20),
            ],
            Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
            if (descricao != null) ...[
              const SizedBox(height: 8),
              Text(
                descricao!,
                style: texto.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (acao != null) ...[const SizedBox(height: 24), acao!],
          ],
        ),
      ),
    );
  }
}

/// Carregando padronizado.
class Carregando extends StatelessWidget {
  const Carregando({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 3),
    ),
  );
}

/// Barra de saúde da memória de um assunto.
class BarraSaude extends StatelessWidget {
  final String nome;
  final double retencao; // 0..1
  final Color cor;
  final String? rotulo;

  const BarraSaude({
    super.key,
    required this.nome,
    required this.retencao,
    required this.cor,
    this.rotulo,
  });

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(nome, style: texto.titleSmall)),
              Text(
                rotulo ?? '${(retencao * 100).round()}%',
                style: texto.labelMedium?.copyWith(color: cor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: retencao.clamp(0, 1)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) =>
                  LinearProgressIndicator(value: v, minHeight: 8, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}
