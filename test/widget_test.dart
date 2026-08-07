// Smoke test: la app arranca sin lanzar excepciones.

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_gateway_app/main.dart';

void main() {
  testWidgets('La app monta el shell inicial', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Equipos'), findsWidgets);
  });
}
