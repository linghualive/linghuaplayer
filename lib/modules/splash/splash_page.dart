import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import 'splash_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final SplashController _controller;

  // Icon entrance animation
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconSlide;

  // Text reveal animation
  late final AnimationController _textController;

  // Glow pulse animation
  late final AnimationController _glowController;

  // Exit animation
  late final AnimationController _exitController;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;

  bool _exitTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SplashController>();

    // Icon entrance: elastic scale + fade + slide up
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _iconSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Text reveal: gradient sweep
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Glow pulse: repeating
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Exit: scale up + fade out
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.offAllNamed(AppRoutes.home);
      }
    });

    _textController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tryExit();
      }
    });

    // Listen for controller ready
    ever(_controller.isReady, (ready) {
      if (ready) _tryExit();
    });

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textController.forward();

    // Start glow pulse after icon is mostly visible
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _glowController.repeat(reverse: true);
  }

  void _tryExit() {
    if (_exitTriggered) return;
    if (_controller.isReady.value && _textController.isCompleted) {
      _exitTriggered = true;
      _glowController.stop();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _exitController.forward();
      });
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _exitController,
          _iconController,
          _textController,
          _glowController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fire icon with glow effect
                    Transform.translate(
                      offset: Offset(0, _iconSlide.value),
                      child: Opacity(
                        opacity: _iconOpacity.value,
                        child: Transform.scale(
                          scale: _iconScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(
                                    alpha: 0.3 * _glowController.value,
                                  ),
                                  blurRadius: 40 * _glowController.value,
                                  spreadRadius: 8 * _glowController.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              size: 80,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Text with gradient sweep reveal
                    _buildRevealText(context, primaryColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevealText(BuildContext context, Color primaryColor) {
    final progress = Curves.easeOut.transform(_textController.value);

    return ShaderMask(
      shaderCallback: (bounds) {
        if (progress == 0) {
          return const LinearGradient(
            colors: [Colors.transparent, Colors.transparent],
          ).createShader(bounds);
        }
        final sweepPos = progress * 1.2;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [
            0.0,
            (sweepPos - 0.15).clamp(0.0, 1.0),
            sweepPos.clamp(0.0, 1.0),
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.modulate,
      child: Text(
        'FlameKit',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
      ),
    );
  }
}
