import 'package:face_recognizer/features/calendar/presentation/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CalendarScreen builds and shows core sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

    await tester.pumpAndSettle();

    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Pengingat'), findsWidgets);
    expect(find.byType(ListView), findsOneWidget);
  });
}
