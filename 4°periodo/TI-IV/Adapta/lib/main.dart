import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'tema/tema_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Única coisa lida do disco: a preferência de tema claro/escuro.
  final tema = await carregarTemaSalvo();
  runApp(
    ProviderScope(
      overrides: [temaInicialProvider.overrideWithValue(tema)],
      child: const AdaptaApp(),
    ),
  );
}
