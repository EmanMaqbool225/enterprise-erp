import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_erp/main.dart';

void main() {
  testWidgets('Enterprise ERP smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EnterpriseERPApp(),
      ),
    );
  });
}