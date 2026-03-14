import 'package:flutter_test/flutter_test.dart';
import 'package:medicreminder/main.dart';


void main() {
  testWidgets('App inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('MEDICREMINDER'), findsOneWidget);
    expect(find.text('ADICIONAR PRIMEIRO REMÉDIO'), findsOneWidget);
  });
}
