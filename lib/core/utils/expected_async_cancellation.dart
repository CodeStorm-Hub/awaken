import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/foundation.dart';

/// True for [CancellationException] from `executor_lib` with message `Cancelled`.
///
/// Vector map tile renders are cancelled when the map layer is disposed or the
/// visible tile set changes — expected noise, not a user-facing failure.
bool isExpectedAsyncCancellation(Object error) {
  return error is CancellationException && error.toString() == 'Cancelled';
}

/// Swallows expected vector-tile [CancellationException]s; forwards everything else.
void installExpectedAsyncCancellationHandlers() {
  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isExpectedAsyncCancellation(details.exception)) {
      return;
    }
    previousFlutterOnError?.call(details);
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (isExpectedAsyncCancellation(error)) {
      return true;
    }
    return previousPlatformOnError?.call(error, stack) ?? false;
  };
}
