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
  final arquivos = [
    for (final m in indice['materias'] as List)
      await _lerJson(ler, m['arquivo'] as String),
  ];
  return PacoteConteudo.deMapas(indice, arquivos);
}
