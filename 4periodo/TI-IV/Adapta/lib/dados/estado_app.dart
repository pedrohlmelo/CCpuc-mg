/// Estado compartilhado pelas telas: quem está na sessão, a matéria escolhida
/// e o histórico. Os dados moram no SQLite; aqui ficam só os providers que os
/// entregam às telas.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modelos.dart';
import 'preferencias.dart';
import 'repositorios/conteudo_repositorio.dart';
import 'repositorios/historico_repositorio.dart';
import 'repositorios/usuario_repositorio.dart';
import 'sincronizacao/servico_sincronizacao.dart';

/// Matéria salva nas preferências, lida antes do app subir em `main.dart`.
final idMateriaInicialProvider = Provider<int?>((_) => null);

/// Id da matéria escolhida na tela de matérias. Nulo = estudo guiado (todas).
class IdMateriaSelecionada extends Notifier<int?> {
  @override
  int? build() => ref.watch(idMateriaInicialProvider);

  void selecionar(Materia? materia) {
    state = materia?.id;
    ref.read(preferenciasProvider).gravarIdMateria(materia?.id);
  }
}

final idMateriaSelecionadaProvider =
    NotifierProvider<IdMateriaSelecionada, int?>(IdMateriaSelecionada.new);

final materiaSelecionadaProvider = Provider<Materia?>((ref) {
  final id = ref.watch(idMateriaSelecionadaProvider);
  if (id == null) return null;
  return ref.watch(conteudoProvider).valueOrNull?.materiaPorId(id);
});

/// Sessão: sempre há alguém, nem que seja um visitante.
class SessaoController extends AsyncNotifier<Usuario> {
  @override
  Future<Usuario> build() =>
      ref.watch(usuarioRepositorioProvider).sessaoInicial();

  /// Lança [ErroConta] com a mensagem para a tela.
  Future<void> entrar(String email, String senha) async {
    final resultado = await ref
        .read(usuarioRepositorioProvider)
        .entrar(email, senha);
    if (resultado.novo) {
      await ref
          .read(servicoSincronizacaoProvider)
          .baixarProgresso(resultado.usuario);
    }
    state = AsyncData(resultado.usuario);
  }

  /// Lança [ErroConta] com a mensagem para a tela.
  Future<void> cadastrar(String nome, String email, String senha) async {
    final atual = await future;
    state = AsyncData(
      await ref
          .read(usuarioRepositorioProvider)
          .cadastrar(atual, nome: nome, email: email, senha: senha),
    );
  }

  /// Volta para um visitante novo.
  Future<void> sair() async {
    // Depois do logout as regras do Firestore barram o envio destes dados.
    final atual = state.valueOrNull;
    if (atual != null) {
      await ref.read(servicoSincronizacaoProvider).sincronizar(atual);
    }
    state = AsyncData(await ref.read(usuarioRepositorioProvider).sair());
  }

  /// Visitante criado offline ganha o login anônimo quando a internet volta.
  Future<void> vincularVisitante() async {
    final atual = await future;
    final vinculado = await ref
        .read(usuarioRepositorioProvider)
        .vincularVisitante(atual);
    if (vinculado.uidFirebase != atual.uidFirebase) {
      state = AsyncData(vinculado);
    }
  }
}

final sessaoProvider = AsyncNotifierProvider<SessaoController, Usuario>(
  SessaoController.new,
);

/// Atalho de leitura: nulo só enquanto a sessão carrega.
final usuarioProvider = Provider<Usuario?>(
  (ref) => ref.watch(sessaoProvider).valueOrNull,
);

/// `true` para quem tem conta com e-mail; visitante é `false`.
final entrouProvider = Provider<bool>(
  (ref) => !(ref.watch(usuarioProvider)?.visitante ?? true),
);

/// `true` só quando quem entrou é do grupo. O painel administrativo não
/// aparece nem abre para aluno.
final ehAdminProvider = Provider<bool>(
  (ref) => ref.watch(usuarioProvider)?.isAdmin ?? false,
);

/// Questões respondidas pelo usuário atual, da mais recente para a mais
/// antiga.
class HistoricoController extends AsyncNotifier<List<Resposta>> {
  @override
  Future<List<Resposta>> build() async {
    final usuario = ref.watch(usuarioProvider);
    if (usuario == null) return const [];
    return ref.watch(historicoRepositorioProvider).listar(usuario.id);
  }

  /// Grava a resposta no banco e a coloca na frente da lista.
  Future<void> registrar({
    required int idQuestao,
    required String letra,
    required bool acertou,
    int tempoGasto = 0,
  }) async {
    final usuario = ref.read(usuarioProvider);
    if (usuario == null) return;
    final resposta = await ref
        .read(historicoRepositorioProvider)
        .registrar(
          idUsuario: usuario.id,
          idQuestao: idQuestao,
          letra: letra,
          acertou: acertou,
          tempoGasto: tempoGasto,
        );
    state = AsyncData([resposta, ...state.valueOrNull ?? const []]);
  }
}

final historicoProvider =
    AsyncNotifierProvider<HistoricoController, List<Resposta>>(
      HistoricoController.new,
    );
