import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cached_image.dart';
import '../player_controller.dart';

class PlayerArtwork extends StatefulWidget {
  const PlayerArtwork({super.key});

  @override
  State<PlayerArtwork> createState() => _PlayerArtworkState();
}

class _PlayerArtworkState extends State<PlayerArtwork>
    with TickerProviderStateMixin {
  late final AnimationController _rotationCtrl;
  late final AnimationController _tonearmCtrl;
  late final PlayerController _playerCtrl;

  // Tonearm angle: 0.0 = resting (away), 1.0 = on record
  static const _tonearmRestAngle = -0.5; // radians, lifted away
  static const _tonearmPlayAngle = 0.0; // radians, on the record

  @override
  void initState() {
    super.initState();
    _playerCtrl = Get.find<PlayerController>();

    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _tonearmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: _playerCtrl.isPlaying.value ? 1.0 : 0.0,
    );

    if (_playerCtrl.isPlaying.value) {
      _rotationCtrl.repeat();
    }

    ever(_playerCtrl.isPlaying, (playing) {
      if (!mounted) return;
      if (playing) {
        _tonearmCtrl.forward().then((_) {
          if (mounted) _rotationCtrl.repeat();
        });
      } else {
        _rotationCtrl.stop();
        _tonearmCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _tonearmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final video = _playerCtrl.currentVideo.value;
      if (video == null) return const SizedBox.shrink();

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // Disc takes most of the width, leave room for tonearm overhang
              final discSize = availableWidth * 0.82;
              final tonearmLength = discSize * 0.58;

              return SizedBox(
                width: availableWidth,
                height: discSize + 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Vinyl disc - centered horizontally, slightly left
                    Positioned(
                      left: (availableWidth - discSize) / 2 - 10,
                      top: 16,
                      child: SizedBox(
                        width: discSize,
                        height: discSize,
                        child: AnimatedBuilder(
                          animation: _rotationCtrl,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationCtrl.value * 2 * pi,
                              child: child,
                            );
                          },
                          child: _VinylDisc(imageUrl: video.pic),
                        ),
                      ),
                    ),
                    // Tonearm - pivot at top-right area
                    Positioned(
                      right: (availableWidth - discSize) / 2 + discSize * 0.28,
                      top: -6,
                      child: AnimatedBuilder(
                        animation: _tonearmCtrl,
                        builder: (context, child) {
                          final angle = _tonearmRestAngle +
                              (_tonearmPlayAngle - _tonearmRestAngle) *
                                  Curves.easeInOut
                                      .transform(_tonearmCtrl.value);
                          return Transform.rotate(
                            angle: angle,
                            alignment: Alignment.topCenter,
                            child: child,
                          );
                        },
                        child: _Tonearm(length: tonearmLength),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

/// The tonearm (唱臂) painted with CustomPaint for a realistic look.
class _Tonearm extends StatelessWidget {
  final double length;

  const _Tonearm({required this.length});

  @override
  Widget build(BuildContext context) {
    final width = length * 0.28;
    return SizedBox(
      width: width,
      height: length,
      child: CustomPaint(
        size: Size(width, length),
        painter: _TonearmPainter(),
      ),
    );
  }
}

class _TonearmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;

    // ── Pivot base ──
    final pivotR = size.width * 0.32;
    final pivotCenter = Offset(cx, pivotR);

    // Outer ring
    canvas.drawCircle(
      pivotCenter,
      pivotR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE0E0E0),
            const Color(0xFFA0A0A0),
            const Color(0xFF707070),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
            Rect.fromCircle(center: pivotCenter, radius: pivotR)),
    );
    // Inner ring
    canvas.drawCircle(
      pivotCenter,
      pivotR * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF555555),
            const Color(0xFF888888),
            const Color(0xFF444444),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
            Rect.fromCircle(center: pivotCenter, radius: pivotR * 0.55)),
    );
    // Center dot
    canvas.drawCircle(
      pivotCenter,
      pivotR * 0.18,
      Paint()..color = const Color(0xFFCCCCCC),
    );

    // ── Counterweight (behind pivot) ──
    // Small sphere slightly above pivot
    // (Counterweight sits at the back/top of the arm, visible above pivot)

    // ── Arm body (tapered tube) ──
    final armTop = pivotR * 1.5;
    final armBottom = h * 0.84;
    final armWidthTop = size.width * 0.1;
    final armWidthBottom = size.width * 0.065;

    // Shadow
    final shadowPath = Path()
      ..moveTo(cx - armWidthTop + 1.5, armTop)
      ..lineTo(cx - armWidthBottom + 1.5, armBottom)
      ..lineTo(cx + armWidthBottom + 1.5, armBottom)
      ..lineTo(cx + armWidthTop + 1.5, armTop)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // Arm shape
    final armPath = Path()
      ..moveTo(cx - armWidthTop, armTop)
      ..lineTo(cx - armWidthBottom, armBottom)
      ..lineTo(cx + armWidthBottom, armBottom)
      ..lineTo(cx + armWidthTop, armTop)
      ..close();
    canvas.drawPath(
      armPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF999999),
            Color(0xFFD8D8D8),
            Color(0xFFEEEEEE),
            Color(0xFFD0D0D0),
            Color(0xFF8A8A8A),
          ],
          stops: const [0.0, 0.25, 0.48, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(
            cx - armWidthTop, armTop, armWidthTop * 2, armBottom - armTop)),
    );

    // Highlight line along the arm
    final highlightPath = Path()
      ..moveTo(cx + armWidthTop * 0.15, armTop)
      ..lineTo(cx + armWidthBottom * 0.15, armBottom);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Small joint ring where arm meets headshell
    final jointY = armBottom;
    final jointR = armWidthBottom * 1.6;
    canvas.drawCircle(
      Offset(cx, jointY),
      jointR,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFBBBBBB), Color(0xFF777777)],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, jointY), radius: jointR)),
    );

    // ── Headshell ──
    final headTop = armBottom + jointR * 0.5;
    final headBottom = h * 0.95;
    final headW = size.width * 0.16;

    // Headshell body
    final headRect =
        RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - headW, headTop, headW * 2, headBottom - headTop),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF606060),
            Color(0xFF909090),
            Color(0xFF707070),
          ],
        ).createShader(headRect.outerRect),
    );

    // Stylus (needle)
    final needleTop = headBottom;
    final needleBottom = h;
    canvas.drawLine(
      Offset(cx, needleTop),
      Offset(cx, needleBottom),
      Paint()
        ..color = const Color(0xFFD0D0D0)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    // Needle tip
    canvas.drawCircle(
      Offset(cx, needleBottom),
      1.2,
      Paint()..color = const Color(0xFFEEEEEE),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The vinyl record disc with album art in the center.
class _VinylDisc extends StatelessWidget {
  final String imageUrl;

  const _VinylDisc({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final centerSize = size * 0.55;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl grooves
              CustomPaint(
                size: Size(size, size),
                painter: _GroovesPainter(),
              ),
              // Center album art
              Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF333333),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Center hole
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2A2A2A),
                  border: Border.all(
                    color: const Color(0xFF444444),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints concentric groove lines on the vinyl.
class _GroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final innerRadius = maxRadius * 0.3;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double r = innerRadius; r < maxRadius - 2; r += 3) {
      final opacity =
          0.08 + 0.06 * ((r - innerRadius) / (maxRadius - innerRadius));
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
