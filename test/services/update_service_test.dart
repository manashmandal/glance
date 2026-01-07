import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glance/services/update_service.dart';

class MockHttpClient implements HttpClient {
  final Map<String, dynamic>? responseBody;
  final int statusCode;
  final bool throwError;

  MockHttpClient({
    this.responseBody,
    this.statusCode = 200,
    this.throwError = false,
  });

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (throwError) {
      throw const SocketException('Network error');
    }
    return MockHttpClientRequest(responseBody, statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  final Map<String, dynamic>? responseBody;
  final int statusCode;

  MockHttpClientRequest(this.responseBody, this.statusCode);

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(responseBody, statusCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  final Map<String, dynamic>? responseBody;
  @override
  final int statusCode;

  MockHttpClientResponse(this.responseBody, this.statusCode);

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    final body = responseBody ?? {};
    return Stream.value(
      utf8.encode(jsonEncode(body)),
    ).cast<List<int>>().transform(streamTransformer);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final body = responseBody ?? {};
    return Stream.value(utf8.encode(jsonEncode(body))).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpOverrides extends HttpOverrides {
  final MockHttpClient client;

  MockHttpOverrides(this.client);

  @override
  HttpClient createHttpClient(SecurityContext? context) => client;
}

void main() {
  group('UpdateService', () {
    group('checkForUpdate', () {
      test('returns UpdateInfo when newer version available', () async {
        final mockClient = MockHttpClient(
          responseBody: {
            'tag_name': 'v0.0.9',
            'html_url':
                'https://github.com/manashmandal/glance/releases/tag/v0.0.9',
          },
        );
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNotNull);
        expect(result!.updateAvailable, isTrue);
        expect(result.latestVersion, equals('0.0.9'));
        expect(
          result.downloadUrl,
          equals('https://github.com/manashmandal/glance/releases/tag/v0.0.9'),
        );
      });

      test('returns UpdateInfo with updateAvailable=false when on latest',
          () async {
        final mockClient = MockHttpClient(
          responseBody: {
            'tag_name': 'v0.0.8',
            'html_url':
                'https://github.com/manashmandal/glance/releases/tag/v0.0.8',
          },
        );
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNotNull);
        expect(result!.updateAvailable, isFalse);
        expect(result.latestVersion, equals('0.0.8'));
      });

      test(
          'returns UpdateInfo with updateAvailable=false when ahead of release',
          () async {
        final mockClient = MockHttpClient(
          responseBody: {
            'tag_name': 'v0.0.7',
            'html_url':
                'https://github.com/manashmandal/glance/releases/tag/v0.0.7',
          },
        );
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNotNull);
        expect(result!.updateAvailable, isFalse);
      });

      test('handles tag_name without v prefix', () async {
        final mockClient = MockHttpClient(
          responseBody: {
            'tag_name': '0.0.9',
            'html_url':
                'https://github.com/manashmandal/glance/releases/tag/0.0.9',
          },
        );
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNotNull);
        expect(result!.updateAvailable, isTrue);
        expect(result.latestVersion, equals('0.0.9'));
      });

      test('returns null on network error', () async {
        final mockClient = MockHttpClient(throwError: true);
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNull);
      });

      test('returns null on non-200 status code', () async {
        final mockClient = MockHttpClient(statusCode: 404);
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNull);
      });

      test('returns null on malformed JSON response', () async {
        final mockClient = MockHttpClient(
          responseBody: {'invalid': 'response'},
        );
        HttpOverrides.global = MockHttpOverrides(mockClient);

        final result = await UpdateService.checkForUpdate('0.0.8');

        expect(result, isNull);
      });
    });

    group('compareVersions', () {
      test('correctly compares major versions', () {
        expect(UpdateService.isNewerVersion('2.0.0', '1.0.0'), isTrue);
        expect(UpdateService.isNewerVersion('1.0.0', '2.0.0'), isFalse);
      });

      test('correctly compares minor versions', () {
        expect(UpdateService.isNewerVersion('1.1.0', '1.0.0'), isTrue);
        expect(UpdateService.isNewerVersion('1.0.0', '1.1.0'), isFalse);
      });

      test('correctly compares patch versions', () {
        expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
        expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      });

      test('returns false for equal versions', () {
        expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      });

      test('handles versions with build numbers', () {
        expect(UpdateService.isNewerVersion('1.0.1', '1.0.0+5'), isTrue);
        expect(UpdateService.isNewerVersion('1.0.0+10', '1.0.0+5'), isFalse);
      });
    });
  });
}
