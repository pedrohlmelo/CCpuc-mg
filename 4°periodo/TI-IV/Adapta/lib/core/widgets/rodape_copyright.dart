import 'package:flutter/material.dart';

/// Informações legais do app, centralizadas para reuso.
abstract final class InfoLegal {
  static const anoInicial = 2026;
  static const titular = 'Adapta';

  /// Ex.: "© 2026 Adapta. Todos os direitos reservados."
  static String get copyright {
    final ano = DateTime.now().year;
    final periodo = ano > anoInicial ? '$anoInicial–$ano' : '$anoInicial';
    return '© $periodo $titular. Todos os direitos reservados.';
  }
}

/// Linha de copyright discreta para rodapés de tela.
///
/// [sobreFundoEscuro] usa branco translúcido (cabeçalhos com gradiente);
/// caso contrário usa `onSurfaceVariant` do tema.
class RodapeCopyright extends StatelessWidget {
  final bool sobreFundoEscuro;
  final EdgeInsetsGeometry padding;

  const RodapeCopyright({
    super.key,
    this.sobreFundoEscuro = false,
    this.padding = const EdgeInsets.only(top: 24),
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = sobreFundoEscuro
        ? Colors.white.withValues(alpha: 0.7)
        : tema.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
    return Padding(
      padding: padding,
      child: Text(
        InfoLegal.copyright,
        key: const Key('rodape_copyright'),
        textAlign: TextAlign.center,
        style: tema.textTheme.labelSmall?.copyWith(color: cor),
      ),
    );
  }
}
