import 'package:flutter_test/flutter_test.dart';
import 'package:my_study_planner/main.dart';

void main() {
  testWidgets('My Study Planner app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyStudyPlannerApp());

    expect(find.text('My Study Planner'), findsOneWidget);
    expect(find.text('Study Goals'), findsOneWidget);
    expect(find.text('Add Goal'), findsOneWidget);
  });
}