import 'package:flutter_test/flutter_test.dart';
import 'package:quest_alarm/main.dart';

void main() {
  testWidgets('QuestAlarm app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuestAlarmApp());
    expect(find.text('Sınıf: Savaşçı'), findsOneWidget);
    expect(find.text('Seviye: 1'), findsOneWidget);
    expect(find.text('ALARM KUR'), findsOneWidget);
    expect(find.text('MAĞAZA'), findsOneWidget);
  });
}
