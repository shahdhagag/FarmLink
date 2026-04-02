import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:farmlink/core/theme/app_theme.dart';
import 'shimmer_card.dart';

class CropNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CropNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => const ShimmerCard(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    } else {
      child = _placeholder();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryContainer,
      child: const Icon(Icons.eco_rounded,
          color: AppColors.primary, size: 40),
    );
  }
}

