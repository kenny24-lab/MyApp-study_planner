import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_study_planner/main.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('StudyFlow app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyStudyPlannerApp());

    await tester.pump();

    expect(find.text('StudyFlow'), findsOneWidget);
  });
}