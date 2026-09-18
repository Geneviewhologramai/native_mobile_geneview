// Alapvető smoke teszt a GENEVIEW appra.
// Csak azt ellenőrzi, hogy az app hiba nélkül felépül és megjelenik rajta
// a címsor - ez a lecserélt, a régi "számláló" demo-sablon helyett, ami
// szintaktikai hibákat okozott, mert MyApp-ra hivatkozott (ami nálunk nem létezik).

import 'package:flutter_test/flutter_test.dart';
import 'package:native_mobile_geneview/main.dart';

void main() {
  testWidgets('GENEVIEW app felépül és megjeleníti a címsort', (WidgetTester tester) async {
    await tester.pumpWidget(const GeneviewNativeApp());

    expect(find.text('GENEVIEW // NATIVE MOBILE CORE'), findsOneWidget);
  });
}