import 'dart:convert';
import 'dart:developer';

import '../player_controller.dart';

/// Persisted queue state container.
class SavedQueueState {
  final List<QueueItem> items;
  final int currentIndex;
  final Duration position;
  final PlayMode playMode;

  SavedQueueState({
    required this.items,
    required this.currentIndex,
    required this.position,
    required this.playMode,
  });
}

/// Persists and restores the playback queue across app restarts.
///
/// Uses simple key-value storage (injected via callbacks) to save
/// queue state as JSON. Limits serialized items to 100 to control
/// storage size.
class QueuePersistenceService {
  static const _key = 'saved_queue';
  static const _maxItems = 100;

  final String? Function(String key) read;
  final void Function(String key, String value) write;
  final void Function(String key) remove;

  QueuePersistenceService({
    required this.read,
    required this.write,
    required this.remove,
  });

  /// Save current queue state.
  void saveQueue({
    required List<QueueItem> queue,
    required int currentIndex,
    required Duration position,
    required PlayMode playMode,
  }) {
    final items = queue.take(_maxItems).map((e) => e.toJson()).toList();

    final data = {
      'items': items,
      'currentIndex': currentIndex,
      'positionMs': position.inMilliseconds,
      'playMode': playMode.name,
    };

    write(_key, jsonEncode(data));
  }

  /// Restore saved queue state.
  ///
  /// Returns null if no saved data, or if data is corrupted.
  SavedQueueState? restoreQueue() {
    final raw = read(_key);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>?;
      if (itemsList == null) return null;

      final items = itemsList
          .cast<Map<String, dynamic>>()
          .map((e) => QueueItem.fromJson(e))
          .toList();

      final currentIndex = data['currentIndex'] as int? ?? 0;
      final positionMs = data['positionMs'] as int? ?? 0;
      final playModeName = data['playMode'] as String? ?? 'sequential';

      final playMode = PlayMode.values.firstWhere(
        (m) => m.name == playModeName,
        orElse: () => PlayMode.sequential,
      );

      return SavedQueueState(
        items: items,
        currentIndex: currentIndex,
        position: Duration(milliseconds: positionMs),
        playMode: playMode,
      );
    } catch (e) {
      log('QueuePersistenceService: failed to restore: $e');
      return null;
    }
  }

  /// Clear saved queue data.
  void clear() {
    remove(_key);
  }
}
