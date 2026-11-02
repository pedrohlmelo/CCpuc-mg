import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que o app guarda no Shared Preferences: só configurações. O progresso
/// fica no SQLite, e a sessão logada é persistida pelo próprio Firebase Auth.
///
/// Sem persistência disponível, a leitura devolve nulo e a escrita é ignorada.
class Preferencias {
  static const temaModo = 'tema_modo';
  static const idMateriaSelecionada = 'id_materia_selecionada';
  static const seedConcluido = 'seed_concluido';
  static const versaoConteudo = 'versao_conteudo';
  static const ultimaSincronizacao = 'ultima_sincronizacao';
  static const dataUltimaSessao = 'data_ultima_sessao';

  const Preferencias();

  Future<T?> _ler<T>(T? Function(SharedPreferences) leitura) async {
    try {
      return leitura(await SharedPreferences.getInstance());
    } catch (_) {
      return null;
    }
  }

  Future<void> _gravar(Future<void> Function(SharedPreferences) escrita) async {
    try {
      await escrita(await SharedPreferences.getInstance());
    } catch (_) {
      // Sem persistência disponível: segue só em memória.
    }
  }

  Future<String?> lerTema() => _ler((p) => p.getString(temaModo));

  Future<void> gravarTema(String valor) =>
      _gravar((p) => p.setString(temaModo, valor));

  Future<int?> lerIdMateria() => _ler((p) => p.getInt(idMateriaSelecionada));

  Future<void> gravarIdMateria(int? id) => _gravar(
    (p) => id == null
        ? p.remove(idMateriaSelecionada)
        : p.setInt(idMateriaSelecionada, id),
  );

  Future<bool> lerSeedConcluido() async =>
      await _ler((p) => p.getBool(seedConcluido)) ?? false;

  Future<void> marcarSeedConcluido(int versao) => _gravar((p) async {
    await p.setBool(seedConcluido, true);
    await p.setInt(versaoConteudo, versao);
  });

  Future<DateTime?> lerUltimaSincronizacao() async {
    final texto = await _ler((p) => p.getString(ultimaSincronizacao));
    return texto == null ? null : DateTime.tryParse(texto);
  }

  Future<void> gravarUltimaSincronizacao(DateTime quando) => _gravar(
    (p) => p.setString(ultimaSincronizacao, quando.toIso8601String()),
  );

  Future<void> gravarDataUltimaSessao(DateTime quando) =>
      _gravar((p) => p.setString(dataUltimaSessao, quando.toIso8601String()));
}

final preferenciasProvider = Provider<Preferencias>(
  (_) => const Preferencias(),
);
