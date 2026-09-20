import 'package:flutter_test/flutter_test.dart';
import 'package:roadvision/main.dart';

void main() {
  testWidgets('RoadVision app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const RoadVisionApp());

    expect(find.byType(RoadVisionApp), findsOneWidget);
  });
}
