import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Imagem de um enunciado ou de uma alternativa. Tocar abre em tela cheia com
/// zoom. Se a imagem falhar, ou se não estiver no cache e não houver internet,
/// mostra a descrição num quadro.
///
/// [url] começa com `asset:` nas figuras embutidas; link de rede vem das
/// questões do Firestore e fica no cache depois de carregado.
class ImagemQuestao extends StatelessWidget {
  final String? url;
  final String? caminhoLocal;
  final String? descricao;
  final double alturaMaxima;

  /// Nos testes, um cache sem disco e sem rede.
  final BaseCacheManager? cache;

  const ImagemQuestao({
    super.key,
    required this.url,
    this.caminhoLocal,
    this.descricao,
    this.alturaMaxima = 220,
    this.cache,
  });

  Widget _imagem(BuildContext context, BoxFit ajuste) {
    Widget quadro() => Container(
      key: const Key('imagem_indisponivel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(descricao ?? 'Imagem indisponível'),
    );
    Widget falha(BuildContext context, Object erro, StackTrace? pilha) =>
        quadro();

    final local = caminhoLocal;
    final origem = url ?? '';
    if (local != null) {
      return Image.file(
        File(local),
        fit: ajuste,
        semanticLabel: descricao,
        errorBuilder: falha,
      );
    }
    if (origem.startsWith('asset:')) {
      return Image.asset(
        origem.substring('asset:'.length),
        fit: ajuste,
        semanticLabel: descricao,
        errorBuilder: falha,
      );
    }
    return CachedNetworkImage(
      imageUrl: origem,
      cacheManager: cache,
      fit: ajuste,
      placeholder: (_, _) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => quadro(),
    );
  }

  void _ampliar(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (contexto) => Scaffold(
          key: const Key('tela_imagem'),
          appBar: AppBar(leading: const CloseButton()),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(child: _imagem(contexto, BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('imagem_questao'),
      onTap: () => _ampliar(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaMaxima),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _imagem(context, BoxFit.contain),
        ),
      ),
    );
  }
}
