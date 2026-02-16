import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../search_controller.dart' as app;

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with TickerProviderStateMixin {
  late final app.SearchController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacity;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<app.SearchController>();
    _controller.initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
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
    _controller.startListening();
  }

  void _onLongPressEnd() {
    setState(() => _pressed = false);
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();
    _controller.stopListeningAndAnalyze();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final listening = _controller.isListening.value;
      final analyzing = _controller.isAnalyzing.value;
      final text = _controller.speechText.value;

      return Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 140,
            height: 140,
            child: Center(
              child: GestureDetector(
                onLongPressStart: analyzing ? null : (_) => _onLongPressStart(),
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
                    if (listening)
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, _) {
                          return Container(
                            width: 80 * _rippleAnimation.value,
                            height: 80 * _rippleAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: _rippleOpacity.value),
                                width: 2.5,
                              ),
                            ),
                          );
                        },
                      ),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        double scale;
                        if (_pressed && !listening) {
                          scale = 0.88;
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
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: listening
                              ? theme.colorScheme.primary
                              : analyzing
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : theme.colorScheme.primaryContainer,
                          boxShadow: listening
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: analyzing
                            ? const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3),
                                ),
                              )
                            : Icon(
                                Icons.mic,
                                size: 36,
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
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: analyzing
                ? Text(
                    '正在为你挑选音乐...',
                    key: const ValueKey('analyzing'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : listening && text.isNotEmpty
                    ? Container(
                        key: ValueKey('speech_$text'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : listening
                        ? Text(
                            '正在聆听...',
                            key: const ValueKey('listening'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Text(
                            '长按说出你想听的音乐',
                            key: const ValueKey('idle'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
          ),
        ],
      );
    });
  }
}
