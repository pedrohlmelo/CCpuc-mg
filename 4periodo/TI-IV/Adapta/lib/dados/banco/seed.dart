/// Pacote inicial embutido no app, gerado do Firestore por
/// `ferramentas/conteudo/gerar_pacote_inicial.py`.
library;

import 'pacote_conteudo.dart';
import 'pacote_inicial.g.dart';

int get versaoPacoteInicial => pacoteInicialMeta['versao'] as int;

PacoteConteudo lerPacoteInicial() => PacoteConteudo.deDocumentos(
  pacoteInicialMeta,
  pacoteInicialMaterias,
  pacoteInicialQuestoes,
);
