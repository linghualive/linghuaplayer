import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/data/models/browse_models.dart';
import 'package:flamekit/data/models/playback_info.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/sources/music_source_adapter.dart';
import 'package:flamekit/data/sources/music_source_registry.dart';

// --- Mocks ---

class MockMusicSourceAdapter extends Mock implements MusicSourceAdapter {}

// --- Helpers ---

SearchVideoModel _track({
  MusicSource source = MusicSource.bilibili,
  String title = 'Song',
  String author = 'Artist',
  int id = 1,
  String bvid = 'BV000',
}) {
  return SearchVideoModel(
    id: id,
    author: author,
    title: title,
    duration: '3:00',
    bvid: bvid,
    source: source,
  );
}

PlaybackInfo _playbackInfo({String sourceId = 'test'}) {
  return PlaybackInfo(
    audioStreams: [
      StreamOption(url: 'https://audio.$sourceId.com/stream.m4a'),
    ],
    sourceId: sourceId,
  );
}

void main() {
  late MusicSourceRegistry registry;
  late MockMusicSourceAdapter sourceA;
  late MockMusicSourceAdapter sourceB;

  setUp(() {
    registry = MusicSourceRegistry();

    sourceA = MockMusicSourceAdapter();
    when(() => sourceA.sourceId).thenReturn('bilibili');
    when(() => sourceA.displayName).thenReturn('B站');
    when(() => sourceA.isAvailable).thenReturn(true);

    sourceB = MockMusicSourceAdapter();
    when(() => sourceB.sourceId).thenReturn('netease');
    when(() => sourceB.displayName).thenReturn('网易云');
    when(() => sourceB.isAvailable).thenReturn(true);
  });

  group('register / unregister', () {
    test('register adds source and getSource retrieves it', () {
      registry.register(sourceA);
      expect(registry.getSource('bilibili'), same(sourceA));
    });

    test('register overwrites existing source with same id', () {
      final sourceA2 = MockMusicSourceAdapter();
      when(() => sourceA2.sourceId).thenReturn('bilibili');
      when(() => sourceA2.displayName).thenReturn('B站v2');
      when(() => sourceA2.isAvailable).thenReturn(true);

      registry.register(sourceA);
      registry.register(sourceA2);

      expect(registry.getSource('bilibili'), same(sourceA2));
    });

    test('unregister removes source', () {
      registry.register(sourceA);
      registry.unregister('bilibili');

      expect(registry.getSource('bilibili'), isNull);
    });
  });

  group('getSource', () {
    test('returns null for unknown id', () {
      expect(registry.getSource('unknown'), isNull);
    });

    test('returns registered source', () {
      registry.register(sourceA);
      registry.register(sourceB);

      expect(registry.getSource('bilibili'), same(sourceA));
      expect(registry.getSource('netease'), same(sourceB));
    });
  });

  group('getSourceForTrack', () {
    test('returns source matching track source', () {
      registry.register(sourceA);
      registry.register(sourceB);

      final track = _track(source: MusicSource.bilibili);
      expect(registry.getSourceForTrack(track), same(sourceA));
    });

    test('returns null when source not registered', () {
      registry.register(sourceA);

      final track = _track(source: MusicSource.qqmusic);
      expect(registry.getSourceForTrack(track), isNull);
    });
  });

  group('availableSources', () {
    test('returns only available sources', () {
      final unavailable = MockMusicSourceAdapter();
      when(() => unavailable.sourceId).thenReturn('offline');
      when(() => unavailable.displayName).thenReturn('Offline');
      when(() => unavailable.isAvailable).thenReturn(false);

      registry.register(sourceA);
      registry.register(unavailable);
      registry.register(sourceB);

      final available = registry.availableSources;
      expect(available.length, 2);
      expect(available.map((s) => s.sourceId), containsAll(['bilibili', 'netease']));
    });
  });

  group('resolvePlaybackWithFallback', () {
    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(_track());
    });

    test('preferred source direct resolve succeeds', () async {
      registry.register(sourceA);
      final track = _track(source: MusicSource.bilibili);
      final info = _playbackInfo(sourceId: 'bilibili');

      when(() => sourceA.resolvePlayback(track))
          .thenAnswer((_) async => info);

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
      );

      expect(result, isNotNull);
      expect(result!.$1.sourceId, 'bilibili');
      expect(result.$2, same(track));
    });

    test('preferred source resolves via search when track is from different source', () async {
      registry.register(sourceA);
      registry.register(sourceB);

      final track = _track(source: MusicSource.netease, title: 'MySong', author: 'MyArtist');
      final searchTrack = _track(source: MusicSource.bilibili, title: 'MySong', id: 99);
      final info = _playbackInfo(sourceId: 'bilibili');

      when(() => sourceA.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => SearchResult(
            tracks: [searchTrack],
            hasMore: false,
          ));
      when(() => sourceA.resolvePlayback(searchTrack))
          .thenAnswer((_) async => info);

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
      );

      expect(result, isNotNull);
      expect(result!.$1.sourceId, 'bilibili');
      expect(result.$2, same(searchTrack));
    });

    test('falls back to track own source when preferred source fails', () async {
      registry.register(sourceA);
      registry.register(sourceB);

      final track = _track(source: MusicSource.netease, title: 'MySong', author: 'MyArtist');
      final info = _playbackInfo(sourceId: 'netease');

      // Preferred source fails
      when(() => sourceA.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('network error'));

      // Track's own source succeeds
      when(() => sourceB.resolvePlayback(track))
          .thenAnswer((_) async => info);

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
      );

      expect(result, isNotNull);
      expect(result!.$1.sourceId, 'netease');
      expect(result.$2, same(track));
    });

    test('full fallback chain tries other sources', () async {
      final sourceC = MockMusicSourceAdapter();
      when(() => sourceC.sourceId).thenReturn('gdstudio');
      when(() => sourceC.displayName).thenReturn('GD');
      when(() => sourceC.isAvailable).thenReturn(true);

      registry.register(sourceA);
      registry.register(sourceB);
      registry.register(sourceC);

      final track = _track(source: MusicSource.bilibili, title: 'MySong', author: 'MyArtist');
      final fallbackTrack = _track(source: MusicSource.gdstudio, id: 777);
      final info = _playbackInfo(sourceId: 'gdstudio');

      // Preferred source (bilibili) fails direct resolve
      when(() => sourceA.resolvePlayback(track))
          .thenThrow(Exception('fail'));

      // Netease fallback search fails
      when(() => sourceB.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => SearchResult(tracks: [], hasMore: false));

      // GDStudio fallback succeeds
      when(() => sourceC.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => SearchResult(
            tracks: [fallbackTrack],
            hasMore: false,
          ));
      when(() => sourceC.resolvePlayback(fallbackTrack))
          .thenAnswer((_) async => info);

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
      );

      expect(result, isNotNull);
      expect(result!.$1.sourceId, 'gdstudio');
    });

    test('enableFallback false disables cross-source fallback', () async {
      registry.register(sourceA);
      registry.register(sourceB);

      final track = _track(source: MusicSource.bilibili);

      // Direct resolve fails
      when(() => sourceA.resolvePlayback(track))
          .thenAnswer((_) async => null);

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
        enableFallback: false,
      );

      expect(result, isNull);
      // sourceB should NOT have been called
      verifyNever(() => sourceB.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          ));
    });

    test('all sources fail returns null', () async {
      registry.register(sourceA);
      registry.register(sourceB);

      final track = _track(source: MusicSource.bilibili);

      when(() => sourceA.resolvePlayback(track))
          .thenThrow(Exception('fail'));
      when(() => sourceB.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => SearchResult(tracks: [], hasMore: false));

      final result = await registry.resolvePlaybackWithFallback(track);

      expect(result, isNull);
    });

    test('resolves without preferredSourceId using track own source', () async {
      registry.register(sourceB);

      final track = _track(source: MusicSource.netease);
      final info = _playbackInfo(sourceId: 'netease');

      when(() => sourceB.resolvePlayback(track))
          .thenAnswer((_) async => info);

      final result = await registry.resolvePlaybackWithFallback(track);

      expect(result, isNotNull);
      expect(result!.$1.sourceId, 'netease');
    });

    test('skips own source when it matches preferredSourceId', () async {
      // If preferredSourceId == track.source, own source step should not re-try
      registry.register(sourceA);

      final track = _track(source: MusicSource.bilibili);

      // Direct resolve returns null (track belongs to preferred source)
      when(() => sourceA.resolvePlayback(track))
          .thenAnswer((_) async => null);
      // Search also returns empty
      when(() => sourceA.searchTracks(
            keyword: any(named: 'keyword'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => SearchResult(tracks: [], hasMore: false));

      final result = await registry.resolvePlaybackWithFallback(
        track,
        preferredSourceId: 'bilibili',
        enableFallback: false,
      );

      // resolvePlayback should only be called once (in the preferred source direct path)
      verify(() => sourceA.resolvePlayback(track)).called(1);
      expect(result, isNull);
    });
  });
}
