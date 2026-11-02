/// Carrega o conteúdo embutido no app, que fica em `assets/conteudo/`.
library;

import 'dart:convert';

import 'pacote_conteudo.dart';

/// Lê um asset como texto. No app é o `rootBundle`; nos testes, o disco.
typedef LeitorAsset = Future<String> Function(String caminho);

const pastaConteudo = 'assets/conteudo';

Future<Map<String, dynamic>> _lerJson(LeitorAsset ler, String arquivo) async =>
    jsonDecode(await ler('$pastaConteudo/$arquivo')) as Map<String, dynamic>;

/// Versão do conteúdo embutido, sem ler os arquivos das matérias.
Future<int> lerVersaoDosAssets(LeitorAsset ler) async =>
    (await _lerJson(ler, 'indice.json'))['versao'] as int;

Future<PacoteConteudo> lerPacoteDosAssets(LeitorAsset ler) async {
  final indice = await _lerJson(ler, 'indice.json');
  final materias = <Map<String, dynamic>>[];
  final questoes = <Map<String, dynamic>>[];
  for (final m in (indice['materias'] as List).cast<Map<String, dynamic>>()) {
    final arquivo = await _lerJson(ler, m['arquivo'] as String);
    materias.add({...m, ...arquivo});
    questoes.addAll((arquivo['questoes'] as List).cast<Map<String, dynamic>>());
  }
  return PacoteConteudo.deDocumentos(indice, materias, questoes);
}
