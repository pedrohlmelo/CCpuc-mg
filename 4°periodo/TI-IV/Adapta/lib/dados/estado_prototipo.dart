/// Estado de navegação do protótipo, tudo em memória.
///
/// Guarda apenas o que a interface precisa lembrar enquanto alguém clica pelas
/// telas: quem entrou, a matéria escolhida e as questões respondidas na
/// demonstração. Nada é salvo em disco e nada é calculado aqui. Fechar o app
/// zera tudo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dados_exemplo.dart';
import 'modelos.dart';

/// Matéria escolhida na tela de matérias. Nulo = estudo guiado (todas).
final materiaSelecionadaProvider = StateProvider<Materia?>((_) => null);

/// Quem está usando o app. **Nulo enquanto ninguém entrou**, que é como o app
/// abre: a tela inicial não inventa um nome nem deixa estudar.
///
/// As telas de login e cadastro apenas preenchem este valor. Não há
/// autenticação: conferir e-mail, senha e papel é trabalho do backend.
final usuarioProvider = StateProvider<Usuario?>((_) => null);

/// Atalho de leitura: `true` depois que alguém entrou.
final entrouProvider = Provider<bool>(
  (ref) => ref.watch(usuarioProvider) != null,
);

/// `true` só quando quem entrou é do grupo. O painel administrativo não
/// aparece nem abre para aluno.
final ehAdminProvider = Provider<bool>(
  (ref) => ref.watch(usuarioProvider)?.isAdmin ?? false,
);

/// E-mail que entra como administrador enquanto não há backend. Fica aqui,
/// e não na interface, porque o aluno não deve saber que o painel existe.
const emailAdminDemo = 'admin@adapta.app';

/// Questões respondidas, da mais recente para a mais antiga.
///
/// Sem ninguém na sessão a lista é vazia. Ao entrar, carrega o histórico de
/// exemplo, que representa o que aquele aluno já teria estudado.
class HistoricoPrototipo extends Notifier<List<Resposta>> {
  @override
  List<Resposta> build() {
    if (ref.watch(usuarioProvider) == null) return const [];
    return historicoExemplo()..sort((a, b) => b.quando.compareTo(a.quando));
  }

  /// Registra a resposta na frente da lista (a tela de histórico lê daqui).
  void registrar({required int idQuestao, required String letra}) {
    state = [
      Resposta(
        idQuestao: idQuestao,
        letraEscolhida: letra,
        quando: DateTime.now(),
      ),
      ...state,
    ];
  }
}

final historicoProvider = NotifierProvider<HistoricoPrototipo, List<Resposta>>(
  HistoricoPrototipo.new,
);
