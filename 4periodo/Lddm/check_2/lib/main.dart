import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dados/habitos_repositorio.dart';
import 'dominio/habitos_store.dart';
import 'ui/tela_habitos.dart';

void main() {
  final repo = HabitosRepositorio();

  runApp(
    ChangeNotifierProvider(
      create: (_) => HabitosStore(repo)..carregar(),
      child: const DiarioApp(),
    ),
  );
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
