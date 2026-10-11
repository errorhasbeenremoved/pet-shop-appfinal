import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop_app/widgets/validators.dart';

void main() {
  group('requiredText', () {
    test('rejects null, empty and whitespace', () {
      expect(requiredText(null, 'Название'), isNotNull);
      expect(requiredText('', 'Название'), isNotNull);
      expect(requiredText('   ', 'Название'), isNotNull);
    });
    test('accepts non-empty value', () {
      expect(requiredText('Корм для кошек', 'Название'), isNull);
    });
  });
  group('emailValidator', () {
    test('rejects malformed email',
        () => expect(emailValidator('abc'), isNotNull));
    test('accepts valid email',
        () => expect(emailValidator('user@example.com'), isNull));
  });
  group('positiveInt', () {
    test('rejects zero and decimals', () {
      expect(positiveInt('0', label: 'Остаток'), isNotNull);
      expect(positiveInt('1.5', label: 'Остаток'), isNotNull);
    });
    test('accepts positive integer',
        () => expect(positiveInt('12', label: 'Остаток'), isNull));
  });
  test('phone validator rejects letters',
      () => expect(phoneValidator('call-me'), isNotNull));
  test('selection validator requires one option', () {
    expect(selectionRequired([], label: 'Категория'), isNotNull);
    expect(selectionRequired([2], label: 'Категория'), isNull);
  });
}
