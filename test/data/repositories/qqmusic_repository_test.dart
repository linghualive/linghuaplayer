import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/data/models/search/search_video_model.dart';
import 'package:flamekit/data/providers/qqmusic_provider.dart';
import 'package:flamekit/data/repositories/qqmusic_repository.dart';

class MockQqMusicProvider extends Mock implements QqMusicProvider {}

void main() {
  late MockQqMusicProvider mockProvider;
  late QqMusicRepository repository;

  Response fakeResponse(Map<String, dynamic> data) {
    return Response(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: ''),
    );
  }

  setUp(() {
    mockProvider = MockQqMusicProvider();
    repository = QqMusicRepository(provider: mockProvider);
  });

  group('QqMusicRepository', () {
    group('searchSongs', () {
      test('maps QQ song list to SearchVideoModel list', () async {
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({
                  'data': {
                    'song': {
                      'totalnum': 100,
                      'list': [
                        {
                          'songid': 123,
                          'songmid': '001abc',
                          'songname': '晴天',
                          'singer': [
                            {'id': 1, 'mid': 's001', 'name': '周杰伦'}
                          ],
                          'albumid': 456,
                          'albummid': 'a001',
                          'albumname': '叶惠美',
                          'interval': 269,
                        }
                      ],
                    }
                  }
                }));

        final result = await repository.searchSongs(keyword: '晴天');

        expect(result.tracks.length, 1);
        expect(result.totalCount, 100);

        final track = result.tracks.first;
        expect(track.id, 123);
        expect(track.title, '晴天');
        expect(track.author, '周杰伦');
        expect(track.bvid, '001abc'); // songmid stored in bvid
        expect(track.source, MusicSource.qqmusic);
        expect(track.duration, '4:29'); // 269 seconds
        expect(track.pic, contains('a001'));
      });

      test('handles multiple singers joined by /', () async {
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({
                  'data': {
                    'song': {
                      'totalnum': 1,
                      'list': [
                        {
                          'songid': 789,
                          'songmid': '002def',
                          'songname': '合唱曲',
                          'singer': [
                            {'id': 1, 'name': '歌手A'},
                            {'id': 2, 'name': '歌手B'},
                          ],
                          'albummid': 'b002',
                          'interval': 180,
                        }
                      ],
                    }
                  }
                }));

        final result = await repository.searchSongs(keyword: '合唱');
        expect(result.tracks.first.author, '歌手A / 歌手B');
      });

      test('returns empty result on error', () async {
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenThrow(Exception('network error'));

        final result = await repository.searchSongs(keyword: 'test');
        expect(result.tracks, isEmpty);
        expect(result.totalCount, 0);
      });

      test('returns empty result when data.song is null', () async {
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        final result = await repository.searchSongs(keyword: 'test');
        expect(result.tracks, isEmpty);
      });
    });

    group('getPlayUrl', () {
      test('constructs full URL from CDN domain + purl', () async {
        when(() => mockProvider.getMusicPlayUrl(any(),
                quality: any(named: 'quality'),
                mediaId: any(named: 'mediaId')))
            .thenAnswer((_) async => fakeResponse({
                  'req_0': {
                    'data': {
                      'sip': ['https://dl.stream.qqmusic.qq.com/'],
                      'midurlinfo': [
                        {'purl': 'M500001abc001abc.mp3?vkey=xxx'}
                      ],
                    }
                  }
                }));

        final url = await repository.getPlayUrl('001abc');
        expect(url, 'https://dl.stream.qqmusic.qq.com/M500001abc001abc.mp3?vkey=xxx');
      });

      test('returns null when purl is empty', () async {
        when(() => mockProvider.getMusicPlayUrl(any(),
                quality: any(named: 'quality'),
                mediaId: any(named: 'mediaId')))
            .thenAnswer((_) async => fakeResponse({
                  'req_0': {
                    'data': {
                      'sip': ['https://dl.stream.qqmusic.qq.com/'],
                      'midurlinfo': [
                        {'purl': ''}
                      ],
                    }
                  }
                }));

        final url = await repository.getPlayUrl('001abc');
        expect(url, isNull);
      });

      test('returns null when domain starts with http://ws', () async {
        when(() => mockProvider.getMusicPlayUrl(any(),
                quality: any(named: 'quality'),
                mediaId: any(named: 'mediaId')))
            .thenAnswer((_) async => fakeResponse({
                  'req_0': {
                    'data': {
                      'sip': ['http://ws.stream.qqmusic.qq.com/'],
                      'midurlinfo': [
                        {'purl': 'M500001abc.mp3'}
                      ],
                    }
                  }
                }));

        final url = await repository.getPlayUrl('001abc');
        expect(url, isNull);
      });

      test('returns null on error', () async {
        when(() => mockProvider.getMusicPlayUrl(any(),
                quality: any(named: 'quality'),
                mediaId: any(named: 'mediaId')))
            .thenThrow(Exception('network error'));

        final url = await repository.getPlayUrl('001abc');
        expect(url, isNull);
      });
    });

    group('getLyrics', () {
      test('decodes Base64 LRC and parses it', () async {
        // Encode a simple LRC
        final lrc = '[00:05.20]Hello World\n[00:10.00]Second Line';
        final encoded = base64Encode(utf8.encode(lrc));

        when(() => mockProvider.getLyrics(any()))
            .thenAnswer((_) async => fakeResponse({'lyric': encoded}));

        final lyrics = await repository.getLyrics('001abc');
        expect(lyrics, isNotNull);
        expect(lyrics!.lines.length, 2);
        expect(lyrics.lines[0].text, 'Hello World');
        expect(lyrics.lines[1].text, 'Second Line');
      });

      test('returns null when lyric field is empty', () async {
        when(() => mockProvider.getLyrics(any()))
            .thenAnswer((_) async => fakeResponse({'lyric': ''}));

        final lyrics = await repository.getLyrics('001abc');
        expect(lyrics, isNull);
      });

      test('returns null on error', () async {
        when(() => mockProvider.getLyrics(any()))
            .thenThrow(Exception('network error'));

        final lyrics = await repository.getLyrics('001abc');
        expect(lyrics, isNull);
      });
    });

    group('getHotkeys', () {
      test('parses hotkey list', () async {
        when(() => mockProvider.getHotkeys()).thenAnswer((_) async =>
            fakeResponse({
              'code': 0,
              'data': {
                'hotkey': [
                  {'k': '周杰伦', 'n': 100},
                  {'k': '林俊杰', 'n': 90},
                ]
              }
            }));

        final keywords = await repository.getHotkeys();
        expect(keywords.length, 2);
        expect(keywords[0].keyword, '周杰伦');
        expect(keywords[1].keyword, '林俊杰');
        expect(keywords[0].position, 0);
        expect(keywords[1].position, 1);
      });

      test('returns empty list on non-zero code', () async {
        when(() => mockProvider.getHotkeys())
            .thenAnswer((_) async => fakeResponse({'code': -1}));

        final keywords = await repository.getHotkeys();
        expect(keywords, isEmpty);
      });
    });

    group('getSearchSuggestions', () {
      test('extracts song names from smartbox', () async {
        when(() => mockProvider.getSmartbox(any())).thenAnswer((_) async =>
            fakeResponse({
              'code': 0,
              'data': {
                'song': {
                  'itemlist': [
                    {'name': '晴天', 'singer': '周杰伦'},
                    {'name': '夜曲', 'singer': '周杰伦'},
                  ]
                }
              }
            }));

        final suggestions = await repository.getSearchSuggestions('周');
        expect(suggestions, ['晴天', '夜曲']);
      });
    });

    group('getHotPlaylists', () {
      test('maps playlist list to PlaylistBrief', () async {
        when(() => mockProvider.getPlaylistsByCategory(
              limit: any(named: 'limit'),
              categoryId: any(named: 'categoryId'),
              sortId: any(named: 'sortId'),
              page: any(named: 'page'),
            )).thenAnswer((_) async => fakeResponse({
              'code': 0,
              'data': {
                'list': [
                  {
                    'dissid': '7011264340',
                    'dissname': '经典华语',
                    'imgurl': 'https://example.com/cover.jpg',
                    'listennum': 50000,
                  }
                ]
              }
            }));

        final playlists = await repository.getHotPlaylists();
        expect(playlists.length, 1);
        expect(playlists[0].id, '7011264340');
        expect(playlists[0].name, '经典华语');
        expect(playlists[0].sourceId, 'qqmusic');
      });
    });

    group('getPlaylistDetail', () {
      test('parses cdlist response with songs', () async {
        when(() => mockProvider.getPlaylistDetail(any()))
            .thenAnswer((_) async => fakeResponse({
                  'cdlist': [
                    {
                      'dissname': '经典华语',
                      'logo': 'https://example.com/logo.jpg',
                      'desc': '精选华语经典',
                      'visitnum': 100000,
                      'songnum': 50,
                      'nick': '音乐达人',
                      'songlist': [
                        {
                          'songid': 111,
                          'songmid': 'mid001',
                          'songname': 'Song A',
                          'singer': [
                            {'name': 'Artist'}
                          ],
                          'albummid': 'alb001',
                          'interval': 200,
                        }
                      ]
                    }
                  ]
                }));

        final detail = await repository.getPlaylistDetail('123');
        expect(detail, isNotNull);
        expect(detail!.name, '经典华语');
        expect(detail.creatorName, '音乐达人');
        expect(detail.tracks.length, 1);
        expect(detail.tracks[0].title, 'Song A');
      });

      test('returns null when cdlist is empty', () async {
        when(() => mockProvider.getPlaylistDetail(any()))
            .thenAnswer((_) async => fakeResponse({'cdlist': []}));

        final detail = await repository.getPlaylistDetail('123');
        expect(detail, isNull);
      });
    });

    group('getToplists', () {
      test('maps topList to ToplistItem', () async {
        when(() => mockProvider.getTopLists())
            .thenAnswer((_) async => fakeResponse({
                  'code': 0,
                  'data': {
                    'topList': [
                      {
                        'id': 4,
                        'topTitle': '巅峰榜·流行指数',
                        'picUrl': 'https://example.com/top.jpg',
                        'songList': [
                          {'songname': '歌名', 'singername': '歌手'},
                        ],
                      }
                    ]
                  }
                }));

        final toplists = await repository.getToplists();
        expect(toplists.length, 1);
        expect(toplists[0].id, '4');
        expect(toplists[0].name, '巅峰榜·流行指数');
        expect(toplists[0].trackPreviews.first, '歌名 - 歌手');
      });
    });

    group('getToplistDetail', () {
      test('parses ranking songs from req_1', () async {
        when(() => mockProvider.getToplistDetail(any(),
                limit: any(named: 'limit'),
                offset: any(named: 'offset'),
                period: any(named: 'period')))
            .thenAnswer((_) async => fakeResponse({
                  'req_1': {
                    'code': 0,
                    'data': {
                      'data': {
                        'topId': 4,
                        'title': '流行榜',
                        'totalNum': 100,
                        'song': [
                          {
                            'rank': 1,
                            'songInfo': {
                              'id': 999,
                              'mid': 'mid999',
                              'name': '热门歌',
                              'singer': [
                                {'name': '歌手'}
                              ],
                              'interval': 240,
                              'albummid': 'alb999',
                            }
                          }
                        ]
                      }
                    }
                  }
                }));

        final detail = await repository.getToplistDetail(4);
        expect(detail, isNotNull);
        expect(detail!.name, '流行榜');
        expect(detail.tracks.length, 1);
        expect(detail.tracks[0].title, '热门歌');
      });
    });

    group('getArtistDetail', () {
      test('parses singer info and hot songs', () async {
        when(() => mockProvider.getSingerHotSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({
                  'singer': {
                    'code': 0,
                    'data': {
                      'singer_info': {
                        'name': '周杰伦',
                        'mid': 'mid001',
                        'pic': 'pic_url',
                      },
                      'total_song': 500,
                      'songlist': [
                        {
                          'songid': 1,
                          'songmid': 'sm001',
                          'songname': '晴天',
                          'singer': [
                            {'name': '周杰伦'}
                          ],
                          'albummid': 'alb001',
                          'interval': 269,
                        }
                      ]
                    }
                  }
                }));

        final detail = await repository.getArtistDetail('mid001');
        expect(detail, isNotNull);
        expect(detail!.name, '周杰伦');
        expect(detail.musicSize, 500);
        expect(detail.hotSongs.length, 1);
        expect(detail.hotSongs[0].title, '晴天');
      });
    });

    group('getAlbumDetail', () {
      test('parses album info with song list', () async {
        when(() => mockProvider.getAlbumInfo(any()))
            .thenAnswer((_) async => fakeResponse({
                  'code': 0,
                  'data': {
                    'name': '叶惠美',
                    'singername': '周杰伦',
                    'desc': '经典专辑',
                    'list': [
                      {
                        'songid': 1,
                        'songmid': 'sm001',
                        'songname': '晴天',
                        'singer': [
                          {'name': '周杰伦'}
                        ],
                        'albummid': 'alb001',
                        'interval': 269,
                      }
                    ]
                  }
                }));

        final detail = await repository.getAlbumDetail('alb001');
        expect(detail, isNotNull);
        expect(detail!.name, '叶惠美');
        expect(detail.artistName, '周杰伦');
        expect(detail.tracks.length, 1);
      });

      test('returns null on non-zero code', () async {
        when(() => mockProvider.getAlbumInfo(any()))
            .thenAnswer((_) async => fakeResponse({'code': -1}));

        final detail = await repository.getAlbumDetail('alb001');
        expect(detail, isNull);
      });
    });

    group('_formatDuration', () {
      test('formats duration correctly', () async {
        // Indirectly test through song mapping
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({
                  'data': {
                    'song': {
                      'totalnum': 1,
                      'list': [
                        {
                          'songid': 1,
                          'songmid': 'mid1',
                          'songname': 'Test',
                          'singer': [],
                          'albummid': '',
                          'interval': 65, // 1:05
                        }
                      ]
                    }
                  }
                }));

        final result = await repository.searchSongs(keyword: 'test');
        expect(result.tracks.first.duration, '1:05');
      });

      test('handles zero duration', () async {
        when(() => mockProvider.searchSongs(any(),
                limit: any(named: 'limit'), page: any(named: 'page')))
            .thenAnswer((_) async => fakeResponse({
                  'data': {
                    'song': {
                      'totalnum': 1,
                      'list': [
                        {
                          'songid': 1,
                          'songmid': 'mid1',
                          'songname': 'Test',
                          'singer': [],
                          'albummid': '',
                          'interval': 0,
                        }
                      ]
                    }
                  }
                }));

        final result = await repository.searchSongs(keyword: 'test');
        expect(result.tracks.first.duration, '0:00');
      });
    });
  });
}
