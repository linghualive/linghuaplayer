import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_controller.dart' as app;

class VoiceFab extends StatefulWidget {
  const VoiceFab({super.key});

  @override
  State<VoiceFab> createState() => _VoiceFabState();
}

class _VoiceFabState extends State<VoiceFab> with TickerProviderStateMixin {
  late final app.SearchController _ctrl;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacity;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<app.SearchController>();
    _ctrl.initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rippleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    setState(() => _pressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_pressed && mounted) {
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
      }
    });
    _ctrl.startListening();
  }

  void _onLongPressEnd() {
    setState(() => _pressed = false);
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();
    _ctrl.stopListeningAndAnalyze();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double fabSize = 56;

    return Obx(() {
      final listening = _ctrl.isListening.value;
      final analyzing = _ctrl.isAnalyzing.value;
      final text = _ctrl.speechText.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Status label above FAB
          if (listening || analyzing)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                analyzing
                    ? '正在为你挑选音乐...'
                    : text.isNotEmpty
                    ? text
                    : '正在聆听...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onInverseSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // FAB button
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: SizedBox(
              width: fabSize * 2,
              height: fabSize * 2,
              child: Center(
                child: GestureDetector(
                  onLongPressStart: analyzing
                      ? null
                      : (_) => _onLongPressStart(),
                  onLongPressEnd: analyzing ? null : (_) => _onLongPressEnd(),
                  onLongPressCancel: analyzing
                      ? null
                      : () {
                          setState(() => _pressed = false);
                          _pulseController.stop();
                          _pulseController.reset();
                          _rippleController.stop();
                          _rippleController.reset();
                        },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple wave
                      if (listening)
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, _) {
                            return Container(
                              width: fabSize * _rippleAnimation.value,
                              height: fabSize * _rippleAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: _rippleOpacity.value,
                                  ),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),

                      // Main button
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          double scale;
                          if (_pressed && !listening) {
                            scale = 0.85;
                          } else if (listening) {
                            scale = _pulseAnimation.value;
                          } else {
                            scale = 1.0;
                          }
                          return AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: fabSize,
                          height: fabSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: listening
                                ? theme.colorScheme.primary
                                : analyzing
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: listening
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.black.withValues(alpha: 0.15),
                                blurRadius: listening ? 24 : 8,
                                spreadRadius: listening ? 4 : 1,
                                offset: listening
                                    ? Offset.zero
                                    : const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: analyzing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.mic,
                                  size: 28,
                                  color: listening
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
