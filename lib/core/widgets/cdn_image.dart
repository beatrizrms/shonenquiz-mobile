import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Imagem da CDN com cache em disco + memória (persiste entre sessões).
/// Usada em todas as camadas do avatar para evitar redownload.
class CdnImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  /// Mostra um spinner enquanto baixa pela primeira vez.
  final bool showLoader;

  /// Widget exibido em caso de erro (default: nada).
  final Widget? errorWidget;

  /// Largura de exibição (px lógicos). Quando informada, o decode é reamostrado
  /// para ~esse tamanho (× densidade da tela), reduzindo memória e tempo de decode.
  /// O arquivo em disco continua em resolução cheia (baixado uma vez só).
  final double? cacheWidth;

  const CdnImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.showLoader = false,
    this.errorWidget,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final memWidth = cacheWidth == null
        ? null
        : (cacheWidth! * MediaQuery.of(context).devicePixelRatio).round();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: memWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: Duration.zero,
      placeholder: showLoader
          ? (context, _) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple),
                ),
              )
          : null,
      errorWidget: (context, _, _) => errorWidget ?? const SizedBox.shrink(),
    );
  }
}
