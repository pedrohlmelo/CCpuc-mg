import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dados/habitos_repositorio.dart';
import 'dados/preferencias.dart';
import 'dominio/habitos_store.dart';
import 'ui/tela_habitos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = HabitosRepositorio();
  final escuro = await lerTema();

  runApp(
    ChangeNotifierProvider(
      create: (_) => HabitosStore(repo)..carregar(),
      child: DiarioApp(temaEscuro: escuro),
    ),
  );
}

class DiarioApp extends StatefulWidget {
  const DiarioApp({super.key, this.temaEscuro = false});

  final bool temaEscuro;

  @override
  State<DiarioApp> createState() => _DiarioAppState();
}

class _DiarioAppState extends State<DiarioApp> {
  late bool _escuro = widget.temaEscuro;

  void _alternarTema(bool escuro) {
    setState(() => _escuro = escuro);
    salvarTema(escuro);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diário de Hábitos',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A5276),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    themeMode: _escuro ? ThemeMode.dark : ThemeMode.light,
    home: TelaPrincipal(escuro: _escuro, onTema: _alternarTema),
  );
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key, required this.escuro, required this.onTema});

  final bool escuro;
  final ValueChanged<bool> onTema;

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final telas = [
      const TelaHabitos(),
      TelaResumo(escuro: widget.escuro, onTema: widget.onTema),
    ];

    return Scaffold(
      body: telas[_aba],
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
}
