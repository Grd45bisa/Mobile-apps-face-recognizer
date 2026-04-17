import 'package:face_recognizer/features/report/presentation/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ReportScreen builds dynamic report sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));

    await tester.pumpAndSettle();

    expect(find.text('Laporan'), findsOneWidget);
    expect(find.text('Rentang Tanggal'), findsOneWidget);
    expect(find.text('Jam Kerja per Periode 7 Hari'), findsOneWidget);
    expect(find.text('Komposisi Kehadiran'), findsOneWidget);
    expect(find.text('Insight Singkat'), findsOneWidget);
  });
}
