import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'habitos_store.dart';
import 'tela_novo_habito.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => HabitosStore(),
    child: const DiarioApp(),
  ),
);

class DiarioApp extends StatelessWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diário de Hábitos',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
      useMaterial3: true,
    ),
    home: const TelaPrincipal(),
  );
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _aba = 0;

  final _telas = const [
    TelaHabitos(),
    TelaResumo(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _telas[_aba],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _aba,
      onDestinationSelected: (i) => setState(() => _aba = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.list), label: 'Hábitos'),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Resumo'),
      ],
    ),
  );
}

class TelaHabitos extends StatelessWidget {
  const TelaHabitos({super.key});

  @override
  Widget build(BuildContext context) {
    final habitos = context.watch<HabitosStore>().habitos;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Hábitos')),
      body: ListView.builder(
        itemCount: habitos.length,
        itemBuilder: (_, i) => Dismissible(
          key: ObjectKey(habitos[i]),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => context.read<HabitosStore>().remover(habitos[i]),
          child: ListTile(
            leading: Icon(habitos[i].icone),
            title: Text(habitos[i].nome),
            subtitle: Text(habitos[i].meta),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => context.read<HabitosStore>().remover(habitos[i]),
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

class TelaResumo extends StatelessWidget {
  const TelaResumo({super.key});

  @override
  Widget build(BuildContext context) {
    final total = context.watch<HabitosStore>().habitos.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
      body: Center(child: Text('$total hábitos')),
    );
  }
}
