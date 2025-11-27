// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glance/main.dart' as app;

import 'package:glance/screens/dashboard_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import 'dart:io';
import 'dart:convert';
import 'dart:async';

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return Stream.value(utf8.encode('{}')).cast<List<int>>().transform(streamTransformer);
  }
  
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(utf8.encode('{}')).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Set a large landscape surface size
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Mock package info
    PackageInfo.setMockInitialValues(
      appName: 'Glance',
      packageName: 'com.example.glance',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(const app.GlanceApp());
    await tester.pump(); // Start futures
    await tester.pump(const Duration(milliseconds: 100)); // Wait for futures to complete

    // Verify that the dashboard screen is present.
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify branding
    expect(find.text('Glance'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);

    // Reset surface size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
