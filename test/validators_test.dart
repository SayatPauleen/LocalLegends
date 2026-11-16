import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/providers/auth_provider.dart';
import 'package:local_legends/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email accepts a valid address', () {
      expect(Validators.email('pauleen@example.com'), isNull);
    });
    test('email rejects empty and malformed input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });
    test('password needs 8+ chars with a letter and a number', () {
      expect(Validators.password('abc12345'), isNull);
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('onlyletters'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
    test('confirm password must match', () {
      expect(Validators.confirmPassword('abc12345', 'abc12345'), isNull);
      expect(Validators.confirmPassword('abc12346', 'abc12345'), isNotNull);
    });
    test('name is required', () {
      expect(Validators.name(' '), isNotNull);
      expect(Validators.name('Pauleen'), isNull);
    });
  });

  group('AuthProvider.messageForCode', () {
    test('wrong credentials share one safe message', () {
      final a = AuthProvider.messageForCode('wrong-password');
      final b = AuthProvider.messageForCode('user-not-found');
      expect(a, b);
    });
    test('unknown codes fall back to a generic message', () {
      expect(AuthProvider.messageForCode('???'), contains('Something went wrong'));
    });
  });
}
