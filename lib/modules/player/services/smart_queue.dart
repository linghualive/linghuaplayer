import '../player_controller.dart';

/// A queue that distinguishes user-added ("Up Next") items from
/// auto-recommended ("Auto Queue") items.
///
/// "Up Next" items always play before "Auto Queue" items.
class SmartQueue {
  final List<QueueItem> _upNext = [];
  final List<QueueItem> _autoQueue = [];

  /// User-added items (play first).
  List<QueueItem> get upNext => List.unmodifiable(_upNext);

  /// Auto-recommended items (play after "up next" is exhausted).
  List<QueueItem> get autoQueue => List.unmodifiable(_autoQueue);

  /// Combined list: up next first, then auto queue.
  List<QueueItem> get allItems => [..._upNext, ..._autoQueue];

  /// Total number of items in both sections.
  int get length => _upNext.length + _autoQueue.length;

  /// Add a user-requested item to "Up Next".
  void addUpNext(QueueItem item) {
    _upNext.add(item);
  }

  /// Add an auto-recommended item to "Auto Queue".
  void addToAutoQueue(QueueItem item) {
    _autoQueue.add(item);
  }

  /// Reorder items within the "Up Next" section.
  void reorderUpNext(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _upNext.length) return;
    if (newIndex < 0 || newIndex > _upNext.length) return;

    final item = _upNext.removeAt(oldIndex);
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _upNext.insert(adjustedNew.clamp(0, _upNext.length), item);
  }

  /// Remove from "Up Next" by index.
  void removeFromUpNext(int index) {
    if (index < 0 || index >= _upNext.length) return;
    _upNext.removeAt(index);
  }

  /// Clear only user-added items.
  void clearUpNext() {
    _upNext.clear();
  }

  /// Clear only auto-recommended items.
  void clearAutoQueue() {
    _autoQueue.clear();
  }

  /// Clear everything.
  void clearAll() {
    _upNext.clear();
    _autoQueue.clear();
  }
}
