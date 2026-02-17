import 'package:flutter_test/flutter_test.dart';
import 'package:flamekit/core/http/qqmusic_http_client.dart';

void main() {
  group('QqMusicHttpClient', () {
    group('hash33', () {
      test('returns consistent hash for a given string', () {
        const input = 'testqrsig123';
        final result1 = QqMusicHttpClient.hash33(input);
        final result2 = QqMusicHttpClient.hash33(input);
        expect(result1, equals(result2));
      });

      test('returns 0 for empty string', () {
        expect(QqMusicHttpClient.hash33(''), equals(0));
      });

      test('returns positive integer within 31-bit range', () {
        final result = QqMusicHttpClient.hash33('some_qrsig_value');
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(2147483647));
      });

      test('produces different hashes for different inputs', () {
        final hash1 = QqMusicHttpClient.hash33('abc');
        final hash2 = QqMusicHttpClient.hash33('def');
        expect(hash1, isNot(equals(hash2)));
      });

      // Verify against known JS implementation output
      test('matches known output for "abc"', () {
        // hash33("abc"):
        //   e=0: e = 0 + (0<<5) + 97 = 97
        //   e=97: e = 97 + (97<<5) + 98 = 97 + 3104 + 98 = 3299
        //   e=3299: e = 3299 + (3299<<5) + 99 = 3299 + 105568 + 99 = 108966
        // 108966 & 2147483647 = 108966
        expect(QqMusicHttpClient.hash33('abc'), equals(108966));
      });
    });

    group('getGtk', () {
      test('returns consistent value for a given p_skey', () {
        const pSkey = 'test_p_skey';
        final result1 = QqMusicHttpClient.getGtk(pSkey);
        final result2 = QqMusicHttpClient.getGtk(pSkey);
        expect(result1, equals(result2));
      });

      test('returns 5381 for empty string', () {
        // hash=5381, no iterations, 5381 & 0x7fffffff = 5381
        expect(QqMusicHttpClient.getGtk(''), equals(5381));
      });

      test('returns positive integer within 31-bit range', () {
        final result = QqMusicHttpClient.getGtk('some_p_skey_value');
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(0x7fffffff));
      });

      test('produces different values for different p_skey', () {
        final gtk1 = QqMusicHttpClient.getGtk('key1');
        final gtk2 = QqMusicHttpClient.getGtk('key2');
        expect(gtk1, isNot(equals(gtk2)));
      });
    });

    group('generateGuid', () {
      test('returns UUID v4 format', () {
        final guid = QqMusicHttpClient.generateGuid();
        // UUID v4 format: 8-4-4-4-12 hex chars (uppercase)
        final uuidRegex = RegExp(
          r'^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$',
        );
        expect(uuidRegex.hasMatch(guid), isTrue, reason: 'GUID=$guid');
      });

      test('generates different GUIDs each time', () {
        final guid1 = QqMusicHttpClient.generateGuid();
        final guid2 = QqMusicHttpClient.generateGuid();
        expect(guid1, isNot(equals(guid2)));
      });

      test('is uppercase', () {
        final guid = QqMusicHttpClient.generateGuid();
        expect(guid, equals(guid.toUpperCase()));
      });
    });

    group('buildFilename', () {
      test('builds 128kbps MP3 filename correctly', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', '128');
        expect(filename, equals('M500001abc001abc.mp3'));
      });

      test('builds 320kbps MP3 filename correctly', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', '320');
        expect(filename, equals('M800001abc001abc.mp3'));
      });

      test('builds m4a filename correctly', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', 'm4a');
        expect(filename, equals('C400001abc001abc.m4a'));
      });

      test('builds flac filename correctly', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', 'flac');
        expect(filename, equals('F000001abc001abc.flac'));
      });

      test('builds ape filename correctly', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', 'ape');
        expect(filename, equals('A000001abc001abc.ape'));
      });

      test('uses mediaId when provided', () {
        final filename = QqMusicHttpClient.buildFilename(
          '001abc', '128', mediaId: '002def',
        );
        expect(filename, equals('M500001abc002def.mp3'));
      });

      test('defaults to 128kbps for unknown quality', () {
        final filename = QqMusicHttpClient.buildFilename('001abc', 'unknown');
        expect(filename, equals('M500001abc001abc.mp3'));
      });
    });
  });
}
