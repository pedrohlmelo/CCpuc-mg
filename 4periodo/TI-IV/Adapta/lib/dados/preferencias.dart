import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que o app guarda no Shared Preferences: só configurações. O progresso
/// fica no SQLite, e a sessão logada é persistida pelo próprio Firebase Auth.
///
/// Sem persistência disponível, a leitura devolve nulo e a escrita é ignorada.
class Preferencias {
  static const temaModo = 'tema_modo';
  static const idMateriaSelecionada = 'id_materia_selecionada';
  static const linguaEstrangeira = 'lingua_estrangeira';
  static const seedConcluido = 'seed_concluido';
  static const versaoConteudo = 'versao_conteudo';
  static const ultimaSincronizacao = 'ultima_sincronizacao';

  /// Versão do Firestore já baixada por inteiro. É separada de
  /// [versaoConteudo], a do pacote inicial: ele sai com a mesma versão do
  /// Firestore, e o aparelho que só tem o pacote ainda precisa baixar o banco.
  static const versaoBanco = 'versao_banco';
  static const ultimaSincronizacaoConteudo = 'ultima_sincronizacao_conteudo';
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

  /// `ingles` ou `espanhol`; nulo enquanto o aluno não escolheu.
  Future<String?> lerLinguaEstrangeira() =>
      _ler((p) => p.getString(linguaEstrangeira));

  Future<void> gravarLinguaEstrangeira(String lingua) =>
      _gravar((p) => p.setString(linguaEstrangeira, lingua));

  Future<int?> lerVersaoConteudo() => _ler((p) => p.getInt(versaoConteudo));

  Future<void> marcarSeedConcluido(int versao) => _gravar((p) async {
    await p.setBool(seedConcluido, true);
    await p.setInt(versaoConteudo, versao);
  });

  Future<int?> lerVersaoBanco() => _ler((p) => p.getInt(versaoBanco));

  Future<void> gravarVersaoBanco(int versao) =>
      _gravar((p) => p.setInt(versaoBanco, versao));

  /// `atualizado_em` da última questão aplicada, de onde o download continua.
  Future<String?> lerUltimaSincronizacaoConteudo() =>
      _ler((p) => p.getString(ultimaSincronizacaoConteudo));

  Future<void> gravarUltimaSincronizacaoConteudo(String atualizadoEm) =>
      _gravar((p) => p.setString(ultimaSincronizacaoConteudo, atualizadoEm));

  /// O pacote inicial acabou de sobrescrever o banco: baixa tudo de novo.
  Future<void> reiniciarDownloadConteudo() => _gravar((p) async {
    await p.remove(versaoBanco);
    await p.remove(ultimaSincronizacaoConteudo);
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
