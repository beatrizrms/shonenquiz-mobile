import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/avatar_catalog.dart';
import 'cdn_image.dart';

/// Renderiza o avatar do gato como sobreposição de PNGs do CDN:
/// imagem da raça (base) + imagem dos olhos por cima (overlay).
/// O olho verde é o padrão da raça, então não recebe overlay.
class CatAvatarView extends StatelessWidget {
  final String breed;
  final String eyeColor;
  final double size;

  /// Cenário de fundo (valor do catálogo); `null` = sem fundo.
  final String? background;

  /// Itens equipados (itemRefs) desenhados como overlays sobre o gato.
  final List<String> equipped;

  /// Quando `false`, renderiza só a raça (sem olho) — útil para miniaturas leves.
  final bool showEyes;

  const CatAvatarView({
    super.key,
    required this.breed,
    required this.eyeColor,
    this.size = 96,
    this.background,
    this.equipped = const [],
    this.showEyes = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgFile = backgroundFileForValue(background);
    // Camadas do gato 20% maiores e ancoradas embaixo-centro (fundo fica cheio).
    final foreSize = size * 1.4;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundo — cenário (atrás de tudo, preenche a área inteira)
            if (bgFile != null)
              CdnImage(url: AppAssets.backgroundUrl(bgFile), fit: BoxFit.cover, cacheWidth: size),

            // Gato + olhos + itens — maiores e ancorados na parte inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: foreSize,
                height: foreSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base — imagem da raça
                    CdnImage(
                      url: AppAssets.catUrl(catFileForBreed(breed)),
                      showLoader: true,
                      cacheWidth: foreSize,
                      errorWidget: CdnImage(
                        url: AppAssets.catUrl(avatarFallbackCatFile),
                        cacheWidth: foreSize,
                        errorWidget: const Center(child: Text('🐱', style: TextStyle(fontSize: 40))),
                      ),
                    ),

                    // Overlay — olhos (sempre, pois a base da raça não tem olhos)
                    if (showEyes)
                      CdnImage(url: AppAssets.eyeUrl(eyeFileForColor(eyeColor)), cacheWidth: foreSize),

                    // Overlays — itens equipados. Conjuntos (set-*) usam a arte do
                    // personagem em store/sets; avulsos usam store/items.
                    for (final ref in equipped)
                      CdnImage(
                        url: ref.startsWith('set-')
                            ? AppAssets.setImageUrl(ref.substring(4))
                            : AppAssets.itemImageUrl(ref),
                        cacheWidth: foreSize,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre o avatar do gato em tela cheia, com o cenário preenchendo a tela.
/// Toque em qualquer lugar (ou no X) para fechar.
Future<void> showCatAvatarFullScreen(
  BuildContext context, {
  required String breed,
  required String eyeColor,
  String? background,
  List<String> equipped = const [],
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (_, _, _) => _CatFullScreen(
        breed: breed,
        eyeColor: eyeColor,
        background: background,
        equipped: equipped,
      ),
    ),
  );
}

class _CatFullScreen extends StatelessWidget {
  final String breed;
  final String eyeColor;
  final String? background;
  final List<String> equipped;
  const _CatFullScreen({required this.breed, required this.eyeColor, this.background, this.equipped = const []});

  @override
  Widget build(BuildContext context) {
    final bgFile = backgroundFileForValue(background);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cenário preenchendo toda a tela
            if (bgFile != null)
              CdnImage(
                url: AppAssets.backgroundUrl(bgFile),
                fit: BoxFit.cover,
                errorWidget: Container(color: AppColors.background),
              )
            else
              Container(color: AppColors.background),

            // Gato grande centralizado (sem fundo próprio — já desenhado acima)
            SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = (constraints.maxHeight < constraints.maxWidth
                            ? constraints.maxHeight
                            : constraints.maxWidth) *
                        0.92;
                    return CatAvatarView(
                      breed: breed,
                      eyeColor: eyeColor,
                      background: null,
                      equipped: equipped,
                      size: size,
                    );
                  },
                ),
              ),
            ),

            // Botão fechar
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
