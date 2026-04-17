import 'package:face_recognizer/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen builds modern overview and reminder section', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pumpAndSettle();

    expect(find.text('Selamat pagi, Pahmi!'), findsOneWidget);
    expect(find.text('Kehadiran Hari Ini'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Pengingat Hari Ini'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan Tracker'), findsOneWidget);
  });
}
