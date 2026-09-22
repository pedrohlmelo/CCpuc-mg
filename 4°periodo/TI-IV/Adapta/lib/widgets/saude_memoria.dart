import 'package:flutter/material.dart';

import '../dados/modelos.dart';
import '../tema/app_tema.dart';

/// Cor de cada estado da memória. As cores são semânticas e iguais nos dois
/// temas (verde / âmbar / vermelho).
Color corDaMemoria(EstadoMemoria estado) => switch (estado) {
  EstadoMemoria.consolidado => CoresMemoria.consolidado,
  EstadoMemoria.emRisco => CoresMemoria.emRisco,
  EstadoMemoria.critico => CoresMemoria.critico,
  EstadoMemoria.naoEstudado => CoresMemoria.naoEstudado,
};

String rotuloDaMemoria(EstadoMemoria estado) => switch (estado) {
  EstadoMemoria.consolidado => 'Consolidado',
  EstadoMemoria.emRisco => 'Em risco',
  EstadoMemoria.critico => 'Crítico',
  EstadoMemoria.naoEstudado => 'Não estudado',
};

/// Legenda das cores usada embaixo das barras de saúde.
class LegendaMemoria extends StatelessWidget {
  const LegendaMemoria({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(EstadoMemoria estado) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: corDaMemoria(estado),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rotuloDaMemoria(estado),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(EstadoMemoria.consolidado),
        item(EstadoMemoria.emRisco),
        item(EstadoMemoria.critico),
      ],
    );
  }
}
