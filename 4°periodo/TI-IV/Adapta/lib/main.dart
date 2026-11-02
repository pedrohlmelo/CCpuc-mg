import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'dados/estado_app.dart';
import 'dados/preferencias.dart';
import 'tema/tema_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lido antes de subir, para a primeira tela já abrir com o tema e a matéria.
  final tema = await carregarTemaSalvo();
  final idMateria = await const Preferencias().lerIdMateria();
  runApp(
    ProviderScope(
      overrides: [
        temaInicialProvider.overrideWithValue(tema),
        idMateriaInicialProvider.overrideWithValue(idMateria),
      ],
      child: const AdaptaApp(),
    ),
  );
}
