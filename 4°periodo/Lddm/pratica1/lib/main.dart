import 'package:flutter/material.dart';

void main() => runApp(const MuseusApp());

class Museu {
  final String nome;
  final String cidade;
  final int salas;

  const Museu(this.nome, this.cidade, this.salas);
}

const List<Museu> museus = [
  Museu('Inhotim', 'Brumadinho', 23),
  Museu('Museu do Amanhã', 'Rio de Janeiro', 8),
  Museu('Pinacoteca', 'São Paulo', 14),
];

int maiorAcervo(List<Museu> lista) {
  int maior = lista.first.salas;
  for (final m in lista) {
    if (m.salas > maior) {
      maior = m.salas;
    }
  }
  return maior;
}

class MuseusApp extends StatelessWidget {
  const MuseusApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Museus',
    home: const TelaMuseus(),
  );
}

class TelaMuseus extends StatelessWidget {
  const TelaMuseus({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Museus'),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final m in museus)
                ListTile(
                  title: Text(m.nome),
                  subtitle: Text('${m.cidade} · ${m.salas} salas'),
                  trailing: const Icon(Icons.museum),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Text('maior acervo: ${maiorAcervo(museus)} salas'),
        ),
      ],
    ),
  );
}
