import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chavePreferencia = 'tema_modo';

/// Modo lido do disco antes do app subir. `main.dart` faz o override;
/// sem override (testes), o app segue o sistema.
final temaInicialProvider = Provider<ThemeMode>((_) => ThemeMode.system);

/// Lê a preferência salva. Chamado uma vez em `main.dart`.
Future<ThemeMode> carregarTemaSalvo() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_chavePreferencia)) {
      'claro' => ThemeMode.light,
      'escuro' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  } catch (_) {
    return ThemeMode.system;
  }
}

/// Estado do tema escolhido pelo usuário (claro/escuro/sistema).
class TemaController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(temaInicialProvider);

  /// Se o modo atual resolve para escuro (considera o brilho do sistema
  /// quando `ThemeMode.system`).
  bool estaEscuro(BuildContext context) => switch (state) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };

  /// Alterna entre claro e escuro a partir do modo efetivo na tela.
  Future<void> alternar(BuildContext context) =>
      definir(estaEscuro(context) ? ThemeMode.light : ThemeMode.dark);

  Future<void> definir(ThemeMode modo) async {
    state = modo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chavePreferencia, switch (modo) {
        ThemeMode.light => 'claro',
        ThemeMode.dark => 'escuro',
        ThemeMode.system => 'sistema',
      });
    } catch (_) {
      // Sem persistência disponível (ex.: testes): mantém só em memória.
    }
  }
}

final temaProvider = NotifierProvider<TemaController, ThemeMode>(
  TemaController.new,
);
