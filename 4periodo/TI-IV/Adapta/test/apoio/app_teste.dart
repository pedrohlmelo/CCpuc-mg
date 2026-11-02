import 'dart:async';

import 'package:adapta/app.dart';
import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/banco/pacote_conteudo.dart';
import 'package:adapta/dados/banco/seed.dart';
import 'package:adapta/dados/sincronizacao/servico_sincronizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<PacoteConteudo> pacoteDeTeste() async => lerPacoteInicial();

/// Banco real em memória. Sem isolate, as consultas terminam dentro do relógio
/// falso dos testes de widget.
BancoLocal bancoDeTeste() {
  sqfliteFfiInit();
  return BancoLocal(
    fabrica: databaseFactoryFfiNoIsolate,
    caminho: inMemoryDatabasePath,
  );
}

/// Rede controlada pelo teste. Começa em modo avião.
class ConectividadeFalsa implements Conectividade {
  bool conectado;
  final _mudancas = StreamController<bool>.broadcast();

  ConectividadeFalsa({this.conectado = false});

  void mudar(bool valor) {
    conectado = valor;
    _mudancas.add(valor);
  }

  @override
  Future<bool> online() async => conectado;

  @override
  Stream<bool> get mudancas => _mudancas.stream;
}

Widget appDeTeste(BancoLocal banco, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        bancoProvider.overrideWithValue(banco),
        conectividadeProvider.overrideWithValue(ConectividadeFalsa()),
        ...overrides,
      ],
      child: const AdaptaApp(),
    );
