enum CircuitState { closed, open, halfOpen }

class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException([this.message = 'Circuit breaker is open']);
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Simple circuit breaker to protect against cascading failures.
/// Opens after [failureThreshold] consecutive failures,
/// then enters half-open state after [resetTimeout] to test recovery.
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
  });

  CircuitState get state => _state;

  /// Check if request is allowed. Throws if circuit is open.
  void checkState() {
    switch (_state) {
      case CircuitState.closed:
        return;
      case CircuitState.open:
        if (_lastFailureTime != null &&
            DateTime.now().difference(_lastFailureTime!) > resetTimeout) {
          _state = CircuitState.halfOpen;
          return;
        }
        throw CircuitBreakerOpenException();
      case CircuitState.halfOpen:
        return; // Allow one test request
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
    }
  }
}
