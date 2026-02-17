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

  // Tonearm swing angle: 0.0 → resting (lifted away), 1.0 → on record
  static const _tonearmRestAngle = -0.45; // radians, lifted away
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
      duration: const Duration(milliseconds: 500),
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
      final imageUrl = video?.pic ?? '';

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final discSize = availableWidth * 0.82;
              final tonearmLength = discSize * 0.55;

              return SizedBox(
                width: availableWidth,
                height: discSize + 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Vinyl disc
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
                          child: _VinylDisc(imageUrl: imageUrl),
                        ),
                      ),
                    ),
                    // Tonearm – pivot at top-right
                    Positioned(
                      right: (availableWidth - discSize) / 2 +
                          discSize * 0.26,
                      top: -4,
                      child: AnimatedBuilder(
                        animation: _tonearmCtrl,
                        builder: (context, child) {
                          final t =
                              Curves.easeInOut.transform(_tonearmCtrl.value);
                          final angle = _tonearmRestAngle +
                              (_tonearmPlayAngle - _tonearmRestAngle) * t;
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

/// Two-segment tonearm with elbow joint, modeled after a real S-type tonearm.
class _Tonearm extends StatelessWidget {
  final double length;

  const _Tonearm({required this.length});

  @override
  Widget build(BuildContext context) {
    // Extra width for the angled headshell overhang
    final width = length * 0.35;
    final height = length * 1.1;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _TonearmPainter(),
      ),
    );
  }
}

class _TonearmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final h = size.height;

    // ── 1. Pivot base ──
    final pivotR = size.width * 0.22;
    final pivotCenter = Offset(cx, pivotR + 2);

    // Base plate (outer)
    canvas.drawCircle(
      pivotCenter,
      pivotR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFD5D5D5),
            Color(0xFFB0B0B0),
            Color(0xFF8A8A8A),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(
            Rect.fromCircle(center: pivotCenter, radius: pivotR)),
    );
    // Inner bearing ring
    canvas.drawCircle(
      pivotCenter,
      pivotR * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFF505050),
            Color(0xFF787878),
            Color(0xFF404040),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
            Rect.fromCircle(center: pivotCenter, radius: pivotR * 0.55)),
    );
    // Center screw
    canvas.drawCircle(
      pivotCenter,
      pivotR * 0.18,
      Paint()..color = const Color(0xFFB8B8B8),
    );

    // ── 2. Counterweight (above pivot) ──
    // Not drawn since it's behind the pivot in this orientation

    // ── 3. Main arm (first segment) ──
    final armStartY = pivotCenter.dy + pivotR * 0.9;
    final elbowY = h * 0.72;
    final armW = size.width * 0.055; // thin cylindrical tube

    // Arm shadow
    _drawRoundedBar(
      canvas,
      Offset(cx + 1.5, armStartY),
      Offset(cx + 1.5, elbowY),
      armW,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Arm body – metallic gradient
    _drawRoundedBar(
      canvas,
      Offset(cx, armStartY),
      Offset(cx, elbowY),
      armW,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF909090),
            Color(0xFFCCCCCC),
            Color(0xFFE8E8E8),
            Color(0xFFCCCCCC),
            Color(0xFF858585),
          ],
          stops: const [0.0, 0.25, 0.45, 0.7, 1.0],
        ).createShader(
            Rect.fromLTWH(cx - armW, armStartY, armW * 2, elbowY - armStartY)),
    );

    // ── 4. Elbow joint ──
    final jointR = armW * 1.8;
    final jointCenter = Offset(cx, elbowY);
    canvas.drawCircle(
      jointCenter,
      jointR,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xFFCCCCCC),
            Color(0xFFA0A0A0),
            Color(0xFF686868),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
            Rect.fromCircle(center: jointCenter, radius: jointR)),
    );
    // Joint highlight
    canvas.drawCircle(
      jointCenter + const Offset(-1, -1),
      jointR * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // ── 5. Headshell (second segment, angled) ──
    // Headshell angles ~22° to the left of the main arm
    const headshellAngle = -0.38; // radians (~22°)
    final headshellLen = h * 0.22;

    canvas.save();
    canvas.translate(jointCenter.dx, jointCenter.dy);
    canvas.rotate(headshellAngle);

    final hsW = armW * 0.85; // slightly thinner
    final hsStart = jointR * 0.6;
    final hsEnd = headshellLen;

    // Headshell shadow
    _drawRoundedBar(
      canvas,
      Offset(1.5, hsStart),
      Offset(1.5, hsEnd),
      hsW,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Headshell body
    _drawRoundedBar(
      canvas,
      Offset(0, hsStart),
      Offset(0, hsEnd),
      hsW,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF808080),
            Color(0xFFBBBBBB),
            Color(0xFFD8D8D8),
            Color(0xFFBBBBBB),
            Color(0xFF757575),
          ],
          stops: const [0.0, 0.25, 0.45, 0.7, 1.0],
        ).createShader(Rect.fromLTWH(-hsW, hsStart, hsW * 2, hsEnd - hsStart)),
    );

    // ── 6. Cartridge (rectangular body at headshell end) ──
    final cartW = size.width * 0.08;
    final cartH = headshellLen * 0.22;
    final cartTop = hsEnd - cartH * 0.3;
    final cartRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, cartTop + cartH / 2),
        width: cartW * 2,
        height: cartH,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(
      cartRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF3A3A3A),
            Color(0xFF555555),
            Color(0xFF2E2E2E),
          ],
        ).createShader(cartRect.outerRect),
    );

    // ── 7. Stylus (needle) ──
    final needleStart = cartTop + cartH;
    final needleEnd = needleStart + headshellLen * 0.14;
    canvas.drawLine(
      Offset(0, needleStart),
      Offset(0, needleEnd),
      Paint()
        ..color = const Color(0xFFD0D0D0)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
    // Needle tip
    canvas.drawCircle(
      Offset(0, needleEnd),
      1.0,
      Paint()..color = const Color(0xFFE0E0E0),
    );

    canvas.restore();
  }

  /// Draw a rounded bar (cylinder) between two points.
  void _drawRoundedBar(
      Canvas canvas, Offset start, Offset end, double halfWidth, Paint paint) {
    final path = Path()
      ..moveTo(start.dx - halfWidth, start.dy)
      ..lineTo(end.dx - halfWidth, end.dy)
      ..arcTo(
        Rect.fromCenter(center: end, width: halfWidth * 2, height: halfWidth * 2),
        pi, -pi, false,
      )
      ..lineTo(start.dx + halfWidth, start.dy)
      ..arcTo(
        Rect.fromCenter(
            center: start, width: halfWidth * 2, height: halfWidth * 2),
        0, -pi, false,
      )
      ..close();
    canvas.drawPath(path, paint);
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
