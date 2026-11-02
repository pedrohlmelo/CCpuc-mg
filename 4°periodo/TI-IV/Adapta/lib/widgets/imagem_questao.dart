import 'dart:io';

import 'package:flutter/material.dart';

/// Imagem de um enunciado ou de uma alternativa. Tocar abre em tela cheia com
/// zoom. Se a imagem falhar, mostra a descrição no lugar.
///
/// [url] começa com `asset:` nas figuras embutidas; link de rede e
/// [caminhoLocal] (arquivo baixado) entram com o conteúdo vindo da nuvem.
class ImagemQuestao extends StatelessWidget {
  final String? url;
  final String? caminhoLocal;
  final String? descricao;
  final double alturaMaxima;

  const ImagemQuestao({
    super.key,
    required this.url,
    this.caminhoLocal,
    this.descricao,
    this.alturaMaxima = 220,
  });

  Widget _imagem(BuildContext context, BoxFit ajuste) {
    Widget falha(BuildContext context, Object erro, StackTrace? pilha) =>
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(descricao ?? 'Imagem indisponível'),
        );

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
    return Image.network(
      origem,
      fit: ajuste,
      semanticLabel: descricao,
      errorBuilder: falha,
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
