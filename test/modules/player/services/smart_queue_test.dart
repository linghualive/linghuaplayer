import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/modules/player/player_controller.dart';
import 'package:flamekit/modules/player/services/smart_queue.dart';

QueueItem _queueItem({int id = 1, String title = 'Song'}) {
  return QueueItem(
    video: SearchVideoModel(
      id: id,
      author: 'Artist',
      title: title,
      duration: '3:00',
      source: MusicSource.netease,
    ),
    audioUrl: 'https://audio.com/$id.mp3',
  );
}

void main() {
  late SmartQueue queue;

  setUp(() {
    queue = SmartQueue();
  });

  group('SmartQueue', () {
    test('user-added songs go to "up next" section', () {
      final item = _queueItem(id: 1, title: 'User Song');
      queue.addUpNext(item);

      expect(queue.upNext, [item]);
      expect(queue.autoQueue, isEmpty);
    });

    test('auto-recommended songs go to "auto queue" section', () {
      final item = _queueItem(id: 2, title: 'Auto Song');
      queue.addToAutoQueue(item);

      expect(queue.autoQueue, [item]);
      expect(queue.upNext, isEmpty);
    });

    test('"up next" items come before "auto queue" in allItems', () {
      final auto1 = _queueItem(id: 1, title: 'Auto');
      final user1 = _queueItem(id: 2, title: 'User');

      queue.addToAutoQueue(auto1);
      queue.addUpNext(user1);

      final all = queue.allItems;
      expect(all.length, 2);
      expect(all[0].video.title, 'User');
      expect(all[1].video.title, 'Auto');
    });

    test('clearUpNext only clears user-added items', () {
      queue.addUpNext(_queueItem(id: 1, title: 'User'));
      queue.addToAutoQueue(_queueItem(id: 2, title: 'Auto'));

      queue.clearUpNext();

      expect(queue.upNext, isEmpty);
      expect(queue.autoQueue.length, 1);
    });

    test('clearAutoQueue only clears auto-recommended items', () {
      queue.addUpNext(_queueItem(id: 1, title: 'User'));
      queue.addToAutoQueue(_queueItem(id: 2, title: 'Auto'));

      queue.clearAutoQueue();

      expect(queue.autoQueue, isEmpty);
      expect(queue.upNext.length, 1);
    });

    test('reorderUpNext moves items within up next section', () {
      queue.addUpNext(_queueItem(id: 1, title: 'A'));
      queue.addUpNext(_queueItem(id: 2, title: 'B'));
      queue.addUpNext(_queueItem(id: 3, title: 'C'));

      queue.reorderUpNext(2, 0);

      expect(queue.upNext[0].video.title, 'C');
      expect(queue.upNext[1].video.title, 'A');
      expect(queue.upNext[2].video.title, 'B');
    });

    test('removeFromUpNext removes by index', () {
      queue.addUpNext(_queueItem(id: 1, title: 'A'));
      queue.addUpNext(_queueItem(id: 2, title: 'B'));

      queue.removeFromUpNext(0);

      expect(queue.upNext.length, 1);
      expect(queue.upNext[0].video.title, 'B');
    });

    test('clearAll clears both sections', () {
      queue.addUpNext(_queueItem(id: 1));
      queue.addToAutoQueue(_queueItem(id: 2));

      queue.clearAll();

      expect(queue.allItems, isEmpty);
    });

    test('length returns total of both sections', () {
      queue.addUpNext(_queueItem(id: 1));
      queue.addUpNext(_queueItem(id: 2));
      queue.addToAutoQueue(_queueItem(id: 3));

      expect(queue.length, 3);
    });
  });
}
