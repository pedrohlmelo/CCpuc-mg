import 'package:adapta/widgets/imagem_questao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nada no cache e nenhuma rede para buscar.
class _CacheSemRede extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream.error(Exception('sem rede'));
}

void main() {
  testWidgets('imagem fora do cache e sem rede mostra a descrição', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImagemQuestao(
            url: 'https://enem.dev/figura.png',
            descricao: 'Figura de ENEM 2023, questão 1.',
            cache: _CacheSemRede(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('imagem_indisponivel')), findsOneWidget);
    expect(find.text('Figura de ENEM 2023, questão 1.'), findsOneWidget);
  });
}
