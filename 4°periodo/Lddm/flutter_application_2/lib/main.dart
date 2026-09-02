import 'package:flutter/material.dart';
import 'tela_detalhe.dart';

void main() => runApp(const DiarioApp());

class Habito {
  final String nome;
  final String meta;
  final IconData icone;

  const Habito(this.nome, this.meta, this.icone);
}

Future<List<Habito>> carregarHabitos() async {
  await Future.delayed(const Duration(seconds: 2));

  return const [
    Habito('Beber água', 'Meta: 8 copos por dia', Icons.local_drink),
    Habito('Ler', 'Meta: 20 páginas por dia', Icons.menu_book),
    Habito('Caminhar', 'Meta: 30 minutos por dia', Icons.directions_walk),
    Habito('Dormir cedo', 'Meta: antes das 23h', Icons.bedtime),
  ];
}

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diário de Hábitos',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
      useMaterial3: true,
    ),
    home: const TelaDetalhe(),
  );
}

class TelaHabitos extends StatelessWidget {
  const TelaHabitos({super.key, required this.futuro});

  final Future<List<Habito>> futuro;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus Hábitos')),
    body: FutureBuilder<List<Habito>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Não foi possível carregar'));
        }

        final habitos = snapshot.data ?? const <Habito>[];
        if (habitos.isEmpty) {
          return const Center(child: Text('Nenhum hábito ainda'));
        }

        return ListView.builder(
          itemCount: habitos.length,
          itemBuilder: (context, i) => ListTile(
            leading: Icon(habitos[i].icone),
            title: Text(habitos[i].nome),
            subtitle: Text(habitos[i].meta),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TelaDetalhe()),
            ),
          ),
        );
      },
    ),
  );
}
