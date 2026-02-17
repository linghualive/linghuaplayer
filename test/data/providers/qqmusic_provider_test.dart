import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flamekit/core/http/qqmusic_http_client.dart';
import 'package:flamekit/data/providers/qqmusic_provider.dart';

class MockQqMusicHttpClient extends Mock implements QqMusicHttpClient {}

void main() {
  late MockQqMusicHttpClient mockClient;
  late QqMusicProvider provider;

  Response fakeResponse(Map<String, dynamic> data) {
    return Response(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: ''),
    );
  }

  setUp(() {
    mockClient = MockQqMusicHttpClient();
    provider = QqMusicProvider(client: mockClient);
  });

  group('QqMusicProvider', () {
    group('searchSongs', () {
      test('calls yCommonRequest with correct path and params', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.searchSongs('周杰伦', limit: 20, page: 2);

        final captured = verify(
          () => mockClient.yCommonRequest(
            captureAny(),
            captureAny(),
          ),
        ).captured;

        expect(captured[0], '/soso/fcgi-bin/client_search_cp');
        final params = captured[1] as Map<String, dynamic>;
        expect(params['w'], '周杰伦');
        expect(params['n'], 20);
        expect(params['p'], 2);
      });
    });

    group('getHotkeys', () {
      test('calls correct endpoint', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getHotkeys();

        verify(
          () => mockClient.yCommonRequest(
            '/splcloud/fcgi-bin/gethotkey.fcg',
            any(),
          ),
        ).called(1);
      });
    });

    group('getSmartbox', () {
      test('passes keyword parameter', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getSmartbox('test');

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        final params = captured[1] as Map<String, dynamic>;
        expect(params['key'], 'test');
      });
    });

    group('getSongInfo', () {
      test('calls uCommonRequest with correct module', () async {
        when(() => mockClient.uCommonRequest(any()))
            .thenAnswer((_) async => fakeResponse({'songinfo': {}}));

        await provider.getSongInfo(songmid: '001abc');

        final captured = verify(
          () => mockClient.uCommonRequest(captureAny()),
        ).captured;

        final modules = captured[0] as Map<String, dynamic>;
        final songinfo = modules['songinfo'] as Map<String, dynamic>;
        expect(songinfo['module'], 'music.pf_song_detail_svr');
        expect(songinfo['method'], 'get_song_detail_yqq');
        expect(songinfo['param']['song_mid'], '001abc');
      });
    });

    group('getMusicPlayUrl', () {
      test('calls uCommonRequest with vkey module', () async {
        when(() => mockClient.uCommonRequest(any()))
            .thenAnswer((_) async => fakeResponse({'req_0': {}}));

        await provider.getMusicPlayUrl('001abc', quality: '320');

        final captured = verify(
          () => mockClient.uCommonRequest(captureAny()),
        ).captured;

        final modules = captured[0] as Map<String, dynamic>;
        final req0 = modules['req_0'] as Map<String, dynamic>;
        expect(req0['module'], 'vkey.GetVkeyServer');
        expect(req0['method'], 'CgiGetVkey');

        final param = req0['param'] as Map<String, dynamic>;
        expect((param['songmid'] as List)[0], '001abc');
        expect((param['filename'] as List)[0], contains('M800'));
      });
    });

    group('getLyrics', () {
      test('calls yCommonRequest with songmid', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'lyric': ''}));

        await provider.getLyrics('001abc');

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        expect(captured[0], '/lyric/fcgi-bin/fcg_query_lyric_new.fcg');
        final params = captured[1] as Map<String, dynamic>;
        expect(params['songmid'], '001abc');
      });
    });

    group('getPlaylistCategories', () {
      test('calls correct endpoint', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getPlaylistCategories();

        verify(
          () => mockClient.yCommonRequest(
            '/splcloud/fcgi-bin/fcg_get_diss_tag_conf.fcg',
            any(),
          ),
        ).called(1);
      });
    });

    group('getPlaylistsByCategory', () {
      test('computes sin/ein correctly', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getPlaylistsByCategory(page: 2, limit: 20);

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        final params = captured[1] as Map<String, dynamic>;
        expect(params['sin'], 40); // page=2, limit=20 → sin=40
        expect(params['ein'], 59); // limit*(page+1)-1 = 20*3-1 = 59
      });
    });

    group('getPlaylistDetail', () {
      test('passes disstid parameter', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'cdlist': []}));

        await provider.getPlaylistDetail('7011264340');

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        final params = captured[1] as Map<String, dynamic>;
        expect(params['disstid'], '7011264340');
      });
    });

    group('getTopLists', () {
      test('calls correct endpoint with h5 platform', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getTopLists();

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        final params = captured[1] as Map<String, dynamic>;
        expect(params['platform'], 'h5');
      });
    });

    group('getToplistDetail', () {
      test('uses ToplistInfoServer GetDetail module', () async {
        when(() => mockClient.uCommonRequest(any()))
            .thenAnswer((_) async => fakeResponse({'req_1': {}}));

        await provider.getToplistDetail(4, limit: 50);

        final captured = verify(
          () => mockClient.uCommonRequest(captureAny()),
        ).captured;
        final modules = captured[0] as Map<String, dynamic>;
        final req1 = modules['req_1'] as Map<String, dynamic>;
        expect(req1['module'], 'musicToplist.ToplistInfoServer');
        expect(req1['method'], 'GetDetail');
        expect(req1['param']['topId'], 4);
        expect(req1['param']['num'], 50);
      });
    });

    group('getSingerList', () {
      test('computes sin correctly from page', () async {
        when(() => mockClient.uCommonRequest(any()))
            .thenAnswer((_) async => fakeResponse({'singerList': {}}));

        await provider.getSingerList(page: 3);

        final captured = verify(
          () => mockClient.uCommonRequest(captureAny()),
        ).captured;
        final modules = captured[0] as Map<String, dynamic>;
        final param = modules['singerList']['param'];
        expect(param['sin'], 160); // (3-1)*80 = 160
        expect(param['cur_page'], 3);
      });
    });

    group('getSingerHotSongs', () {
      test('passes singermid and computes sin', () async {
        when(() => mockClient.uCommonRequest(any()))
            .thenAnswer((_) async => fakeResponse({'singer': {}}));

        await provider.getSingerHotSongs('001mid', limit: 10, page: 2);

        final captured = verify(
          () => mockClient.uCommonRequest(captureAny()),
        ).captured;
        final param = captured[0]['singer']['param'];
        expect(param['singermid'], '001mid');
        expect(param['sin'], 10); // (2-1)*10
        expect(param['num'], 10);
      });
    });

    group('getAlbumInfo', () {
      test('passes albummid parameter', () async {
        when(() => mockClient.yCommonRequest(any(), any()))
            .thenAnswer((_) async => fakeResponse({'data': {}}));

        await provider.getAlbumInfo('001album');

        final captured = verify(
          () => mockClient.yCommonRequest(captureAny(), captureAny()),
        ).captured;
        final params = captured[1] as Map<String, dynamic>;
        expect(params['albummid'], '001album');
      });
    });
  });
}
