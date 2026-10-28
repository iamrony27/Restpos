import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_restaurant_pos/main.dart';

void main() {
  testWidgets('Restaurant POS smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantPosApp());
    expect(find.text('Spice Garden POS'), findsOneWidget);
  });
}
