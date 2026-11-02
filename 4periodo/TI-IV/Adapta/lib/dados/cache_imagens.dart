import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache das imagens das questões, o mesmo que a tela usa para mostrá-las.
/// Separado para os testes não dependerem de rede nem de arquivos.
abstract class CacheImagens {
  Future<bool> temNoCache(String url);

  Future<void> preCarregar(String url);
}

class CacheImagensPadrao implements CacheImagens {
  const CacheImagensPadrao();

  @override
  Future<bool> temNoCache(String url) async {
    try {
      return await DefaultCacheManager().getFileFromCache(url) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> preCarregar(String url) async {
    try {
      await DefaultCacheManager().downloadFile(url);
    } catch (_) {
      // A tela tenta de novo ou mostra a descrição da imagem.
    }
  }
}

final cacheImagensProvider = Provider<CacheImagens>(
  (_) => const CacheImagensPadrao(),
);
