import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/tema/tema_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await abrirBanco();
  final tema = await carregarTemaSalvo();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        temaInicialProvider.overrideWithValue(tema),
      ],
      child: const AdaptaApp(),
    ),
  );
}
