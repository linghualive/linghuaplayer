import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';

void main() {
  group('SearchVideoModel.uniqueId', () {
    test('bilibili returns bvid', () {
      final model = SearchVideoModel(
        id: 123,
        author: 'Author',
        title: 'Title',
        duration: '3:00',
        bvid: 'BV1234567890',
        source: MusicSource.bilibili,
      );
      expect(model.uniqueId, 'BV1234567890');
    });

    test('netease returns netease_id', () {
      final model = SearchVideoModel(
        id: 456,
        author: 'Author',
        title: 'Title',
        duration: '3:00',
        source: MusicSource.netease,
      );
      expect(model.uniqueId, 'netease_456');
    });

    test('qqmusic returns qqmusic_id', () {
      final model = SearchVideoModel(
        id: 789,
        author: 'Author',
        title: 'Title',
        duration: '3:00',
        source: MusicSource.qqmusic,
      );
      expect(model.uniqueId, 'qqmusic_789');
    });

    test('gdstudio returns gdstudio_id', () {
      final model = SearchVideoModel(
        id: 101,
        author: 'Author',
        title: 'Title',
        duration: '3:00',
        source: MusicSource.gdstudio,
      );
      expect(model.uniqueId, 'gdstudio_101');
    });
  });

  group('SearchVideoModel serialization', () {
    test('toJson produces correct map', () {
      final model = SearchVideoModel(
        id: 1,
        author: 'Test Author',
        mid: 100,
        title: 'Test Title',
        description: 'Test Desc',
        pic: 'https://example.com/pic.jpg',
        play: 5000,
        danmaku: 200,
        duration: '4:30',
        bvid: 'BV123',
        arcurl: 'https://example.com/video',
        source: MusicSource.netease,
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['author'], 'Test Author');
      expect(json['mid'], 100);
      expect(json['title'], 'Test Title');
      expect(json['description'], 'Test Desc');
      expect(json['pic'], 'https://example.com/pic.jpg');
      expect(json['play'], 5000);
      expect(json['danmaku'], 200);
      expect(json['duration'], '4:30');
      expect(json['bvid'], 'BV123');
      expect(json['arcurl'], 'https://example.com/video');
      expect(json['source'], 'netease');
    });

    test('fromJson restores correct model', () {
      final json = {
        'id': 42,
        'author': 'Artist',
        'mid': 50,
        'title': 'Song',
        'description': 'Album',
        'pic': 'https://pic.jpg',
        'play': 1000,
        'danmaku': 10,
        'duration': '3:15',
        'bvid': 'BV999',
        'arcurl': 'https://video.url',
        'source': 'qqmusic',
      };

      final model = SearchVideoModel.fromJson(json);

      expect(model.id, 42);
      expect(model.author, 'Artist');
      expect(model.mid, 50);
      expect(model.title, 'Song');
      expect(model.description, 'Album');
      expect(model.pic, 'https://pic.jpg');
      expect(model.play, 1000);
      expect(model.danmaku, 10);
      expect(model.duration, '3:15');
      expect(model.bvid, 'BV999');
      expect(model.arcurl, 'https://video.url');
      expect(model.source, MusicSource.qqmusic);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = SearchVideoModel(
        id: 7,
        author: 'Roundtrip',
        mid: 33,
        title: 'Roundtrip Song',
        description: 'Desc',
        pic: 'pic.png',
        play: 999,
        danmaku: 5,
        duration: '2:00',
        bvid: 'BVabc',
        arcurl: 'https://arc',
        source: MusicSource.gdstudio,
      );

      final restored = SearchVideoModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.author, original.author);
      expect(restored.mid, original.mid);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.pic, original.pic);
      expect(restored.play, original.play);
      expect(restored.danmaku, original.danmaku);
      expect(restored.duration, original.duration);
      expect(restored.bvid, original.bvid);
      expect(restored.arcurl, original.arcurl);
      expect(restored.source, original.source);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 1,
        'title': 'Minimal',
      };

      final model = SearchVideoModel.fromJson(json);

      expect(model.id, 1);
      expect(model.title, 'Minimal');
      expect(model.author, '');
      expect(model.mid, 0);
      expect(model.description, '');
      expect(model.pic, '');
      expect(model.play, 0);
      expect(model.danmaku, 0);
      expect(model.duration, '0:00');
      expect(model.bvid, '');
      expect(model.arcurl, '');
      expect(model.source, MusicSource.bilibili); // default
    });
  });

  group('SearchVideoModel._parseSource', () {
    test('parses known source strings', () {
      expect(
        SearchVideoModel.fromJson({'source': 'netease'}).source,
        MusicSource.netease,
      );
      expect(
        SearchVideoModel.fromJson({'source': 'qqmusic'}).source,
        MusicSource.qqmusic,
      );
      expect(
        SearchVideoModel.fromJson({'source': 'gdstudio'}).source,
        MusicSource.gdstudio,
      );
    });

    test('unknown string defaults to bilibili', () {
      expect(
        SearchVideoModel.fromJson({'source': 'unknown_source'}).source,
        MusicSource.bilibili,
      );
    });

    test('non-string value defaults to bilibili', () {
      expect(
        SearchVideoModel.fromJson({'source': 42}).source,
        MusicSource.bilibili,
      );
      expect(
        SearchVideoModel.fromJson({'source': null}).source,
        MusicSource.bilibili,
      );
    });
  });

  group('SearchVideoModel boolean getters', () {
    test('isNetease returns true only for netease source', () {
      final model = SearchVideoModel(
        id: 1, author: '', title: '', duration: '',
        source: MusicSource.netease,
      );
      expect(model.isNetease, isTrue);
      expect(model.isBilibili, isFalse);
      expect(model.isQQMusic, isFalse);
      expect(model.isGdStudio, isFalse);
    });

    test('isBilibili returns true only for bilibili source', () {
      final model = SearchVideoModel(
        id: 1, author: '', title: '', duration: '',
        source: MusicSource.bilibili,
      );
      expect(model.isBilibili, isTrue);
      expect(model.isNetease, isFalse);
    });

    test('isQQMusic returns true only for qqmusic source', () {
      final model = SearchVideoModel(
        id: 1, author: '', title: '', duration: '',
        source: MusicSource.qqmusic,
      );
      expect(model.isQQMusic, isTrue);
      expect(model.isNetease, isFalse);
    });

    test('isGdStudio returns true only for gdstudio source', () {
      final model = SearchVideoModel(
        id: 1, author: '', title: '', duration: '',
        source: MusicSource.gdstudio,
      );
      expect(model.isGdStudio, isTrue);
      expect(model.isNetease, isFalse);
    });
  });

  group('SearchVideoModel._parseInt', () {
    test('fromJson handles play as string', () {
      final model = SearchVideoModel.fromJson({
        'play': '12345',
        'danmaku': '67',
      });
      expect(model.play, 12345);
      expect(model.danmaku, 67);
    });

    test('fromJson handles play as int', () {
      final model = SearchVideoModel.fromJson({
        'play': 99,
        'danmaku': 10,
      });
      expect(model.play, 99);
      expect(model.danmaku, 10);
    });

    test('fromJson handles unparseable play as 0', () {
      final model = SearchVideoModel.fromJson({
        'play': 'not_a_number',
      });
      expect(model.play, 0);
    });
  });
}
