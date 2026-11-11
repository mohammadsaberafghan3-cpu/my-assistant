import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ai/main.dart';

void main() {
  test('offline engine reports local baseline honestly', () {
    final engine = OrionLocalEngine();
    expect(engine.respond('وضعیت'), contains('مدل زبانی محلی: هنوز نصب نشده'));
  });
}
