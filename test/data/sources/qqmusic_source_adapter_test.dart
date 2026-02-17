import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/data/models/browse_models.dart';
import 'package:flamekit/data/models/player/lyrics_model.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/repositories/qqmusic_repository.dart';
import 'package:flamekit/data/sources/qqmusic_source_adapter.dart';

class MockQqMusicRepository extends Mock implements QqMusicRepository {}

void main() {
  late MockQqMusicRepository mockRepo;
  late QqMusicSourceAdapter adapter;

  setUp(() {
    mockRepo = MockQqMusicRepository();
    adapter = QqMusicSourceAdapter(repository: mockRepo);
  });

  group('QqMusicSourceAdapter', () {
    test('sourceId is qqmusic', () {
      expect(adapter.sourceId, 'qqmusic');
    });

    test('displayName is QQ音乐', () {
      expect(adapter.displayName, 'QQ音乐');
    });

    test('isAvailable defaults to true', () {
      expect(adapter.isAvailable, isTrue);
    });

    group('searchTracks', () {
      test('delegates to repository searchSongs', () async {
        final expected = SearchResult(
          tracks: [
            SearchVideoModel(
              id: 1,
              author: 'Test',
              title: 'Song',
              duration: '3:00',
              source: MusicSource.qqmusic,
            ),
          ],
          hasMore: false,
          totalCount: 1,
        );

        when(() => mockRepo.searchSongs(
              keyword: any(named: 'keyword'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => expected);

        final result = await adapter.searchTracks(keyword: '测试');

        verify(() => mockRepo.searchSongs(
              keyword: '测试',
              limit: 30,
              offset: 0,
            )).called(1);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.title, 'Song');
      });
    });

    group('resolvePlayback', () {
      test('returns PlaybackInfo with multiple quality streams', () async {
        final track = SearchVideoModel(
          id: 1,
          author: 'Artist',
          title: 'Song',
          duration: '3:00',
          bvid: '001abc', // songmid
          source: MusicSource.qqmusic,
        );

        when(() => mockRepo.getPlayUrl('001abc', quality: 'flac'))
            .thenAnswer((_) async => 'https://cdn.qq.com/flac.flac');
        when(() => mockRepo.getPlayUrl('001abc', quality: '320'))
            .thenAnswer((_) async => 'https://cdn.qq.com/320.mp3');
        when(() => mockRepo.getPlayUrl('001abc', quality: 'm4a'))
            .thenAnswer((_) async => null);
        when(() => mockRepo.getPlayUrl('001abc', quality: '128'))
            .thenAnswer((_) async => 'https://cdn.qq.com/128.mp3');

        final info = await adapter.resolvePlayback(track);

        expect(info, isNotNull);
        expect(info!.sourceId, 'qqmusic');
        expect(info.audioStreams.length, 3); // flac, 320, 128 (m4a was null)
        expect(info.audioStreams[0].url, 'https://cdn.qq.com/flac.flac');
        expect(info.audioStreams[0].qualityLabel, 'FLAC 无损');
        expect(info.audioStreams[1].url, 'https://cdn.qq.com/320.mp3');
        expect(info.audioStreams[2].url, 'https://cdn.qq.com/128.mp3');
      });

      test('returns null when no quality is available', () async {
        final track = SearchVideoModel(
          id: 1,
          author: 'Artist',
          title: 'Song',
          duration: '3:00',
          bvid: '001abc',
          source: MusicSource.qqmusic,
        );

        when(() => mockRepo.getPlayUrl(any(), quality: any(named: 'quality')))
            .thenAnswer((_) async => null);

        final info = await adapter.resolvePlayback(track);
        expect(info, isNull);
      });

      test('returns null when bvid (songmid) is empty', () async {
        final track = SearchVideoModel(
          id: 1,
          author: 'Artist',
          title: 'Song',
          duration: '3:00',
          bvid: '',
          source: MusicSource.qqmusic,
        );

        final info = await adapter.resolvePlayback(track);
        expect(info, isNull);
      });
    });

    group('getLyrics', () {
      test('delegates to repository with songmid from bvid', () async {
        final track = SearchVideoModel(
          id: 1,
          author: 'Artist',
          title: 'Song',
          duration: '3:00',
          bvid: '001abc',
          source: MusicSource.qqmusic,
        );

        final lyrics = LyricsData(lines: [
          LyricsLine(timestamp: Duration(seconds: 5), text: 'Hello'),
        ]);

        when(() => mockRepo.getLyrics('001abc'))
            .thenAnswer((_) async => lyrics);

        final result = await adapter.getLyrics(track);
        expect(result, isNotNull);
        expect(result!.lines.length, 1);
      });

      test('returns null when bvid is empty', () async {
        final track = SearchVideoModel(
          id: 1,
          author: 'Artist',
          title: 'Song',
          duration: '3:00',
          bvid: '',
          source: MusicSource.qqmusic,
        );

        final result = await adapter.getLyrics(track);
        expect(result, isNull);
      });
    });

    group('getHotSearchKeywords', () {
      test('delegates to repository', () async {
        when(() => mockRepo.getHotkeys()).thenAnswer((_) async => [
              HotKeyword(keyword: '热搜1', position: 0),
            ]);

        final result = await adapter.getHotSearchKeywords();
        expect(result.length, 1);
        expect(result.first.keyword, '热搜1');
      });
    });

    group('getSearchSuggestions', () {
      test('delegates to repository', () async {
        when(() => mockRepo.getSearchSuggestions(any()))
            .thenAnswer((_) async => ['建议1', '建议2']);

        final result = await adapter.getSearchSuggestions('test');
        expect(result, ['建议1', '建议2']);
      });
    });

    group('PlaylistCapability', () {
      test('getHotPlaylists delegates to repository', () async {
        when(() => mockRepo.getHotPlaylists(limit: any(named: 'limit')))
            .thenAnswer((_) async => [
                  PlaylistBrief(
                    id: '1',
                    sourceId: 'qqmusic',
                    name: 'Test Playlist',
                    coverUrl: '',
                  ),
                ]);

        final result = await adapter.getHotPlaylists();
        expect(result.length, 1);
      });

      test('getPlaylistDetail delegates to repository', () async {
        when(() => mockRepo.getPlaylistDetail(any()))
            .thenAnswer((_) async => PlaylistDetail(
                  id: '1',
                  sourceId: 'qqmusic',
                  name: 'Test',
                  coverUrl: '',
                  tracks: [],
                ));

        final result = await adapter.getPlaylistDetail('1');
        expect(result, isNotNull);
        expect(result!.sourceId, 'qqmusic');
      });
    });

    group('ToplistCapability', () {
      test('getToplists delegates to repository', () async {
        when(() => mockRepo.getToplists()).thenAnswer((_) async => [
              ToplistItem(
                id: '4',
                sourceId: 'qqmusic',
                name: '流行榜',
                coverUrl: '',
              ),
            ]);

        final result = await adapter.getToplists();
        expect(result.length, 1);
        expect(result.first.name, '流行榜');
      });

      test('getToplistDetail parses id and delegates', () async {
        when(() => mockRepo.getToplistDetail(4))
            .thenAnswer((_) async => PlaylistDetail(
                  id: '4',
                  sourceId: 'qqmusic',
                  name: '流行榜',
                  coverUrl: '',
                  tracks: [],
                ));

        final result = await adapter.getToplistDetail('4');
        expect(result, isNotNull);
      });

      test('getToplistDetail returns null for invalid id', () async {
        final result = await adapter.getToplistDetail('invalid');
        expect(result, isNull);
      });
    });

    group('ArtistCapability', () {
      test('getArtistDetail delegates to repository', () async {
        when(() => mockRepo.getArtistDetail(any()))
            .thenAnswer((_) async => ArtistDetail(
                  id: 'mid001',
                  sourceId: 'qqmusic',
                  name: '周杰伦',
                  picUrl: '',
                  hotSongs: [],
                ));

        final result = await adapter.getArtistDetail('mid001');
        expect(result, isNotNull);
        expect(result!.name, '周杰伦');
      });
    });

    group('AlbumCapability', () {
      test('getAlbumDetail delegates to repository', () async {
        when(() => mockRepo.getAlbumDetail(any()))
            .thenAnswer((_) async => AlbumDetail(
                  id: 'alb001',
                  sourceId: 'qqmusic',
                  name: '叶惠美',
                  picUrl: '',
                  tracks: [],
                ));

        final result = await adapter.getAlbumDetail('alb001');
        expect(result, isNotNull);
        expect(result!.name, '叶惠美');
      });
    });

    group('getRelatedTracks', () {
      test('searches by artist name', () async {
        final track = SearchVideoModel(
          id: 1,
          author: '周杰伦',
          title: '晴天',
          duration: '3:00',
          source: MusicSource.qqmusic,
        );

        when(() => mockRepo.searchSongs(
              keyword: any(named: 'keyword'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            )).thenAnswer((_) async => SearchResult(
              tracks: [
                SearchVideoModel(
                  id: 2,
                  author: '周杰伦',
                  title: '夜曲',
                  duration: '4:00',
                  source: MusicSource.qqmusic,
                ),
              ],
              totalCount: 1,
            ));

        final result = await adapter.getRelatedTracks(track);
        expect(result.length, 1);
        expect(result.first.title, '夜曲');
      });

      test('returns empty when author is empty', () async {
        final track = SearchVideoModel(
          id: 1,
          author: '',
          title: '晴天',
          duration: '3:00',
          source: MusicSource.qqmusic,
        );

        final result = await adapter.getRelatedTracks(track);
        expect(result, isEmpty);
      });
    });
  });
}
