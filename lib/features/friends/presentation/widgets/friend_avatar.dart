import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/cat_avatar_view.dart';

/// Miniatura do avatar do amigo. Exibe gato padrão se avatarCatId for null.
/// O breed/eyeColor virão de uma lookup futura; por ora usa defaults visuais.
class FriendAvatar extends StatelessWidget {
  final double size;
  final int level;

  const FriendAvatar({super.key, this.size = 44, required this.level});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: CatAvatarView(
            breed: 'tabby-brown',
            eyeColor: 'blue',
            size: size,
            showEyes: size > 32,
          ),
        ),
        Positioned(
          bottom: -4, right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.background, width: 1.5),
            ),
            child: Text('$level', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
