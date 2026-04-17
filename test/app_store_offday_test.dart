import 'package:face_recognizer/shared/models/app_models.dart';
import 'package:face_recognizer/shared/store/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future off day follows weekly off-day settings', () {
    final store = AppStore.instance;
    final settings = store.settings;
    final today = DateTime.now();

    DateTime nextWeekday(int weekday) {
      for (var i = 1; i <= 14; i++) {
        final candidate = today.add(Duration(days: i));
        if (candidate.weekday == weekday) return candidate;
      }
      throw StateError('No matching weekday found.');
    }

    final futureSunday = nextWeekday(DateTime.sunday);
    final futureMonday = nextWeekday(DateTime.monday);

    store.updateSettings(settings.copyWith(offDays: {DateTime.sunday}));

    expect(store.dayStateOf(futureSunday), DayDisplayState.offDay);
    expect(store.dayStateOf(futureMonday), DayDisplayState.futureDay);

    store.updateSettings(settings);
  });
}
