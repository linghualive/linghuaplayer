import 'dart:developer';

/// Service that retries playback with exponential backoff.
///
/// Handles transient errors (network, expired URLs) by retrying
/// with increasing delays. Gives up immediately on format errors.
class PlaybackErrorRecoveryService {
  bool _cancelled = false;

  /// Retry [playAction] with exponential backoff.
  ///
  /// Before each retry, calls [reResolveAction] to refresh URLs.
  /// Returns true if playback succeeded, false if all retries exhausted.
  ///
  /// [FormatException] errors skip retry (unrecoverable codec/format issue).
  Future<bool> retryWithBackoff({
    required Future<void> Function() playAction,
    required Future<void> Function() reResolveAction,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    void Function()? onGiveUp,
  }) async {
    _cancelled = false;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (_cancelled) {
        onGiveUp?.call();
        return false;
      }

      try {
        await playAction();
        return true;
      } on FormatException catch (e) {
        // Format/codec errors are unrecoverable — give up immediately
        log('PlaybackErrorRecovery: format error, giving up: $e');
        onGiveUp?.call();
        return false;
      } catch (e) {
        log('PlaybackErrorRecovery: attempt $attempt/$maxRetries failed: $e');

        if (attempt >= maxRetries) {
          onGiveUp?.call();
          return false;
        }

        if (_cancelled) {
          onGiveUp?.call();
          return false;
        }

        // Exponential backoff
        final delay = initialDelay * (1 << (attempt - 1));
        await Future.delayed(delay);

        if (_cancelled) {
          onGiveUp?.call();
          return false;
        }

        // Re-resolve URLs before retrying
        try {
          await reResolveAction();
        } catch (resolveError) {
          log('PlaybackErrorRecovery: re-resolve failed: $resolveError');
        }
      }
    }

    onGiveUp?.call();
    return false;
  }

  /// Cancel any in-progress retry loop.
  void cancel() {
    _cancelled = true;
  }
}
