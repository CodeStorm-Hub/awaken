import 'dart:async';
import 'dart:io';

import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Unblocks gated territory Realtime/GPS providers in unit tests.
void enableTerritoryMapForTests(ProviderContainer container) {
  container.read(territoryMapReadyProvider.notifier).state = true;
}

/// Returns a transparent 1x1 PNG for any HTTP request in widget tests.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => MockHttpClient();
}

class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(MockHttpClientRequest());
    }
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return MockHttpHeaders();
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static const List<int> _transparentPng = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
    0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
    120, 1, 99, 96, 96, 96, 0, 0, 0, 5, 0, 1, 165, 246, 69, 127, 0, 0, 0, 0,
    73, 69, 78, 68, 174, 66, 96, 130,
  ];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) return 200;
    if (invocation.memberName == #contentLength) return _transparentPng.length;
    if (invocation.memberName == #headers) return MockHttpHeaders();
    return null;
  }
}

/// Signed-out auth stream so [isSignedInProvider] never touches Supabase.instance
/// while [authStateProvider] is loading.
Stream<AuthState> signedOutAuthStateStream() {
  return Stream<AuthState>.value(
    const AuthState(AuthChangeEvent.signedOut, null),
  );
}
