import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class KairoAnimatedLogo extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  
  const KairoAnimatedLogo({Key? key, this.onAnimationComplete}) : super(key: key);

  @override
  State<KairoAnimatedLogo> createState() => _KairoAnimatedLogoState();
}

class _KairoAnimatedLogoState extends State<KairoAnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _arcProgress;
  late Animation<double> _legBarProgress;
  late Animation<double> _strokeOpacity;
  late Animation<double> _fillOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    // Total duration: 2500ms to allow all delays to complete
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Arc stroke: 220ms -> 900ms
    _arcProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.088, 0.36, curve: Curves.easeInOut),
      ),
    );

    // LegBar stroke: 800ms -> 1320ms
    _legBarProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.528, curve: Curves.easeInOut),
      ),
    );

    // Stroke fade out: 1560ms -> 1810ms
    _strokeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.624, 0.724, curve: Curves.easeOut),
      ),
    );

    // Fill fade in: 1560ms -> 1980ms
    _fillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.624, 0.792, curve: Curves.easeInOut),
      ),
    );

    // Glow pulse: 1510ms -> 2410ms (opacity peaks at 1825ms)
    // We break it into two parts for opacity
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.26), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.26, end: 0.0), weight: 65),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.604, 0.964, curve: Curves.easeInOut),
      ),
    );

    _glowScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.72, end: 1.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.604, 0.964, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200 * (1464.5 / 889.48)),
          painter: _KairoLogoPainter(
            arcProgress: _arcProgress.value,
            legBarProgress: _legBarProgress.value,
            strokeOpacity: _strokeOpacity.value,
            fillOpacity: _fillOpacity.value,
            glowOpacity: _glowOpacity.value,
            glowScale: _glowScale.value,
          ),
        );
      },
    );
  }
}

class _KairoLogoPainter extends CustomPainter {
  final double arcProgress;
  final double legBarProgress;
  final double strokeOpacity;
  final double fillOpacity;
  final double glowOpacity;
  final double glowScale;

  _KairoLogoPainter({
    required this.arcProgress,
    required this.legBarProgress,
    required this.strokeOpacity,
    required this.fillOpacity,
    required this.glowOpacity,
    required this.glowScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Colors
    const Color blue = Color(0xFF1a2ecb);
    const Color orange = Color(0xFFFF6B1A);

    // Compute base scale to fit the widget size
    final double viewBoxWidth = 889.481569;
    final double baseScale = size.width / viewBoxWidth;

    // Draw Glow
    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = orange.withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
        
      canvas.save();
      canvas.scale(baseScale, baseScale);
      canvas.translate(450, 700);
      canvas.scale(glowScale, glowScale);
      canvas.drawCircle(Offset.zero, 500, glowPaint);
      canvas.restore();
    }

    // Prepare path drawing transform
    canvas.save();
    canvas.scale(baseScale, baseScale);
    canvas.translate(-1055.518431, 2232.500000);
    canvas.scale(0.1, -0.1);

    final Path topBar = _getTopBarPath();
    final Path arc = _getArcPath();
    final Path legBar = _getLegBarPath();

    // 1. Draw Fills
    if (fillOpacity > 0) {
      // The CSS specifies a drop-shadow. We can simulate it if needed, 
      // but for simplicity we just draw the fills.
      final Paint fillPaintBlue = Paint()
        ..style = PaintingStyle.fill
        ..color = blue.withOpacity(fillOpacity);
        
      final Paint fillPaintOrange = Paint()
        ..style = PaintingStyle.fill
        ..color = orange.withOpacity(fillOpacity);

      canvas.drawPath(topBar, fillPaintBlue);
      canvas.drawPath(arc, fillPaintOrange);
      canvas.drawPath(legBar, fillPaintBlue);
    }

    // 2. Draw Strokes
    if (strokeOpacity > 0) {
      final Paint strokeArc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 60
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = orange.withOpacity(strokeOpacity);

      final Paint strokeLegBar = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 60
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = blue.withOpacity(strokeOpacity);

      _drawProgressPath(canvas, arc, strokeArc, arcProgress);
      _drawProgressPath(canvas, legBar, strokeLegBar, legBarProgress);
    }

    canvas.restore();
  }

  void _drawProgressPath(Canvas canvas, Path path, Paint paint, double progress) {
    if (progress <= 0) return;
    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    for (ui.PathMetric metric in path.computeMetrics()) {
      Path extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KairoLogoPainter oldDelegate) {
    return arcProgress != oldDelegate.arcProgress ||
           legBarProgress != oldDelegate.legBarProgress ||
           strokeOpacity != oldDelegate.strokeOpacity ||
           fillOpacity != oldDelegate.fillOpacity ||
           glowOpacity != oldDelegate.glowOpacity ||
           glowScale != oldDelegate.glowScale;
  }

  Path _getTopBarPath() {
    return Path()
      ..moveTo(13414, 22205)
      ..relativeCubicTo(-50, -66, -360, -484, -690, -930)
      ..relativeCubicTo(-330, -445, -846, -1141, -1145, -1545)
      ..relativeCubicTo(-812, -1094, -837, -1129, -860, -1190)
      ..relativeLineTo(-21, -55)
      ..relativeLineTo(-5, -2752)
      ..relativeCubicTo(-4, -1514, -3, -2753, 0, -2753)
      ..relativeCubicTo(3, 0, 86, 116, 184, 258)
      ..relativeCubicTo(223, 324, 373, 522, 551, 732)
      ..relativeCubicTo(534, 628, 1157, 1159, 1842, 1570)
      ..relativeCubicTo(204, 122, 209, 126, 231, 174)
      ..relativeCubicTo(18, 40, 19, 142, 18, 3286)
      ..relativeCubicTo(0, 1785, -3, 3263, -7, 3285)
      ..relativeLineTo(-7, 40)
      ..relativeLineTo(-91, -120)
      ..close();
  }

  Path _getArcPath() {
    return Path()
      ..moveTo(16890, 15733)
      ..relativeCubicTo(-935, -23, -1804, -237, -2620, -644)
      ..relativeCubicTo(-636, -318, -1179, -709, -1729, -1244)
      ..relativeCubicTo(-1082, -1053, -1726, -2286, -1925, -3685)
      ..relativeCubicTo(-53, -369, -61, -493, -61, -980)
      ..relativeCubicTo(0, -475, 6, -592, 50, -966)
      ..relativeCubicTo(25, -209, 71, -510, 81, -525)
      ..relativeCubicTo(3, -5, 632, -9, 1475, -9)
      ..relativeCubicTo(1442, 0, 1469, 0, 1469, 19)
      ..relativeCubicTo(0, 11, -27, 100, -59, 198)
      ..relativeCubicTo(-145, 435, -201, 775, -201, 1213)
      ..relativeCubicTo(0, 251, 16, 439, 55, 668)
      ..relativeCubicTo(229, 1321, 1154, 2430, 2420, 2902)
      ..relativeCubicTo(326, 121, 646, 191, 1025, 224)
      ..relativeCubicTo(178, 16, 216, 30, 278, 100)
      ..relativeCubicTo(67, 77, 1640, 2193, 1830, 2462)
      ..relativeLineTo(22, 32)
      ..relativeLineTo(-24, 6)
      ..relativeCubicTo(-319, 80, -836, 165, -1226, 201)
      ..relativeCubicTo(-158, 14, -646, 37, -720, 33)
      ..relativeCubicTo(-19, -1, -82, -3, -140, -5)
      ..close();
  }

  Path _getLegBarPath() {
    return Path()
      ..moveTo(16145, 11839)
      ..relativeCubicTo(-156, -62, -428, -200, -557, -282)
      ..relativeCubicTo(-547, -351, -928, -837, -1164, -1484)
      ..relativeCubicTo(-49, -136, -60, -224, -34, -274)
      ..relativeCubicTo(14, -27, 103, -149, 704, -964)
      ..relativeCubicTo(231, -313, 500, -680, 599, -815)
      ..relativeCubicTo(207, -283, 218, -296, 272, -321)
      ..relativeCubicTo(38, -18, 107, -19, 1763, -19)
      ..relativeCubicTo(947, 0, 1722, 2, 1722, 5)
      ..relativeCubicTo(0, 21, -137, 208, -1028, 1408)
      ..relativeCubicTo(-549, 738, -1231, 1657, -1516, 2042)
      ..relativeCubicTo(-285, 385, -530, 710, -545, 722)
      ..relativeCubicTo(-39, 34, -97, 30, -216, -18)
      ..close();
  }
}
