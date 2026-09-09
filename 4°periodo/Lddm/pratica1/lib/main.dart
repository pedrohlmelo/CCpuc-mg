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
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
      useMaterial3: true,
    ),
    home: const TelaMuseus(),
  );
}

class TelaMuseus extends StatelessWidget {
  const TelaMuseus({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Museus'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      ],
    ),
    backgroundColor: const Color(0xFFF2F4F5),
    body: Column(
      children: [
        for (final m in museus)
          Card(
            color: Colors.white,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ListTile(
              title: Text(
                m.nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${m.cidade} · ${m.salas} salas'),
              trailing: const Icon(
                Icons.circle,
                color: Color(0xFFCFE3DC),
                size: 34,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(
            'maior acervo: ${maiorAcervo(museus)} salas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
