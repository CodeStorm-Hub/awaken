import 'package:awaken/features/territory/data/datasources/pending_capture_queue.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const queue = PendingCaptureQueue();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('pending capture queue enqueues and removes by id', () async {
    final capture = PendingCapture(
      id: 'cap-1',
      enqueuedAt: DateTime.utc(2026, 7, 11),
      points: [
        GeoPointEntity(
          latitude: 1,
          longitude: 2,
          timestamp: DateTime.utc(2026, 7, 11),
        ),
        GeoPointEntity(
          latitude: 1.1,
          longitude: 2.1,
          timestamp: DateTime.utc(2026, 7, 11, 0, 1),
        ),
      ],
    );

    await queue.enqueue(capture);
    await queue.enqueue(capture); // dedupe
    expect(await queue.peek(), hasLength(1));

    await queue.remove('cap-1');
    expect(await queue.peek(), isEmpty);
  });
}
