import 'package:flutter/material.dart';

/// Piksel sanat asset'i — keskin ölçekleme ve eksik dosya koruması.
class PixelAssetImage extends StatelessWidget {
  const PixelAssetImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholderSeed,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Placeholder rengi için isteğe bağlı tohum (ör. eşya id'si).
  final String? placeholderSeed;

  @override
  Widget build(BuildContext context) {
    final isNetworkPath =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final image = isNetworkPath
        ? Image.network(
            imagePath,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.none,
            errorBuilder: _errorBuilder,
          )
        : Image.asset(
            imagePath,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.none,
            errorBuilder: _errorBuilder,
          );
    return image;
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return PixelImagePlaceholder(
      width: width,
      height: height,
      seed: placeholderSeed ?? imagePath,
    );
  }
}

/// Görsel bulunamadığında gösterilen pikselli renkli kutu.
class PixelImagePlaceholder extends StatelessWidget {
  const PixelImagePlaceholder({
    super.key,
    this.width,
    this.height,
    required this.seed,
  });

  final double? width;
  final double? height;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromSeed(seed);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PixelPlaceholderPainter(baseColor: color),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: (width != null && height != null)
                ? (width! < height! ? width! : height!) * 0.35
                : 24,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  static Color _colorFromSeed(String seed) {
    final hash = seed.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.38).toColor();
  }
}

class _PixelPlaceholderPainter extends CustomPainter {
  _PixelPlaceholderPainter({required this.baseColor});

  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pixel = 8.0;
    final dark = HSLColor.fromColor(baseColor).withLightness(0.28).toColor();
    final light = HSLColor.fromColor(baseColor).withLightness(0.48).toColor();

    canvas.drawRect(Offset.zero & size, Paint()..color = dark);

    for (var y = 0.0; y < size.height; y += pixel) {
      for (var x = 0.0; x < size.width; x += pixel) {
        final isLight = ((x / pixel).floor() + (y / pixel).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, pixel, pixel),
          Paint()..color = isLight ? light : dark,
        );
      }
    }

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelPlaceholderPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}
