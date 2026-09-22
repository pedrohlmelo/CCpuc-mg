import 'package:flutter/material.dart';

import '../tema/app_tema.dart';

/// Logotipo textual do Adapta. `compacto` para AppBars.
class MarcaAdapta extends StatelessWidget {
  final bool compacto;
  final Color? cor;

  const MarcaAdapta({super.key, this.compacto = false, this.cor});

  @override
  Widget build(BuildContext context) {
    final estilo = compacto
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.displayMedium;
    final corTexto = cor ?? Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Adapta', style: estilo?.copyWith(color: corTexto)),
        SizedBox(width: compacto ? 4 : 6),
        Container(
          width: compacto ? 8 : 12,
          height: compacto ? 8 : 12,
          margin: EdgeInsets.only(top: compacto ? 6 : 14),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppCores.gradienteCamu,
          ),
        ),
      ],
    );
  }
}
