import 'package:adapta/app.dart';
import 'package:adapta/dados/banco/banco_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco real em memória. Sem isolate, as consultas terminam dentro do relógio
/// falso dos testes de widget.
BancoLocal bancoDeTeste() {
  sqfliteFfiInit();
  return BancoLocal(
    fabrica: databaseFactoryFfiNoIsolate,
    caminho: inMemoryDatabasePath,
  );
}

Widget appDeTeste(BancoLocal banco, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [bancoProvider.overrideWithValue(banco), ...overrides],
      child: const AdaptaApp(),
    );
