import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'habitos_store.dart';

class TelaDetalheHabito extends StatelessWidget {
  const TelaDetalheHabito({super.key, required this.habito});

  final Habito habito;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(habito.nome)),
    body: Column(
      children: [
        ListTile(
          leading: Icon(habito.icone),
          title: Text(habito.nome),
          subtitle: Text(habito.meta),
        ),
        FilledButton(
          onPressed: () {
            context.read<HabitosStore>().remover(habito);
            Navigator.pop(context);
          },
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
}
