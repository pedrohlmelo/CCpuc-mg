import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dominio/habito.dart';
import '../dominio/habitos_store.dart';
import 'tela_novo_habito.dart';

IconData iconeHabito(String icone) => switch (icone) {
  'agua' => Icons.local_drink,
  'leitura' => Icons.menu_book,
  'caminhada' => Icons.directions_walk,
  'sono' => Icons.bedtime,
  _ => Icons.check_circle,
};

class TelaHabitos extends StatelessWidget {
  const TelaHabitos({super.key});

  @override
  Widget build(BuildContext context) {
    final habitos = context.watch<HabitosStore>().habitos;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Hábitos')),
      body: ListView.builder(
        itemCount: habitos.length,
        itemBuilder: (_, i) => ListTile(
          leading: Icon(iconeHabito(habitos[i].icone)),
          title: Text(habitos[i].nome),
          subtitle: Text(habitos[i].meta),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaDetalheHabito(habito: habitos[i]),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaNovoHabito()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TelaDetalheHabito extends StatelessWidget {
  const TelaDetalheHabito({super.key, required this.habito});

  final Habito habito;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(habito.nome)),
    body: Column(
      children: [
        ListTile(
          leading: Icon(iconeHabito(habito.icone)),
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
        FilledButton(
          onPressed: () {
            context.read<HabitosStore>().arquivar(habito);
            Navigator.pop(context);
          },
          child: const Text('Arquivar'),
        ),
        FilledButton(
          onPressed: () {
            context.read<HabitosStore>().priorizar(habito);
            Navigator.pop(context);
          },
          child: const Text('Priorizar'),
        ),
      ],
    ),
  );
}

class TelaResumo extends StatelessWidget {
  const TelaResumo({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.watch<HabitosStore>().total;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: Center(child: Text('$total hábitos')),
    );
  }
}
