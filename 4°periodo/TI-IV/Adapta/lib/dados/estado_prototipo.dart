/// Estado de navegação do protótipo, tudo em memória.
///
/// Guarda apenas o que a interface precisa lembrar enquanto alguém clica pelas
/// telas: a matéria escolhida, o nome exibido e as questões respondidas na
/// demonstração. Nada é salvo em disco e nada é calculado aqui. Fechar o app
/// zera tudo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dados_exemplo.dart';
import 'modelos.dart';

/// Matéria escolhida na tela de matérias. Nulo = estudo guiado (todas).
final materiaSelecionadaProvider = StateProvider<Materia?>((_) => null);

/// Nome mostrado nas saudações. A tela de login/cadastro só troca este texto.
final nomeAlunoProvider = StateProvider<String>((_) => 'Bruno');

/// Se a demonstração está "com conta". É só visual: não há autenticação.
final entrouProvider = StateProvider<bool>((_) => false);

/// Questões respondidas, da mais recente para a mais antiga.
class HistoricoPrototipo extends Notifier<List<Resposta>> {
  @override
  List<Resposta> build() =>
      historicoExemplo()..sort((a, b) => b.quando.compareTo(a.quando));

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

final historicoProvider =
    NotifierProvider<HistoricoPrototipo, List<Resposta>>(
      HistoricoPrototipo.new,
    );
