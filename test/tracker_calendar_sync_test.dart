import 'package:face_recognizer/features/calendar/presentation/calendar_screen.dart';
import 'package:face_recognizer/features/timesheet/presentation/timesheet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tracker worklogs are visible on calendar detail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TimesheetScreen()));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Review design mockup dashboard'), findsOneWidget);
  });
}
