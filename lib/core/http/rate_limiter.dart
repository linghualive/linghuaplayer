import 'dart:async';

/// Token bucket rate limiter.
/// Controls request rate to prevent API throttling.
class RateLimiter {
  final int maxTokens;
  final Duration refillInterval;
  int _tokens;
  DateTime _lastRefill;

  RateLimiter({
    this.maxTokens = 10,
    this.refillInterval = const Duration(milliseconds: 200),
  })  : _tokens = maxTokens,
        _lastRefill = DateTime.now();

  Future<void> acquire() async {
    _refill();
    while (_tokens <= 0) {
      await Future.delayed(refillInterval);
      _refill();
    }
    _tokens--;
  }

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    final newTokens = elapsed.inMilliseconds ~/ refillInterval.inMilliseconds;
    if (newTokens > 0) {
      _tokens = (_tokens + newTokens).clamp(0, maxTokens);
      _lastRefill = now;
    }
  }
}
