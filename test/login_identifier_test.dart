import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/services/auth_service.dart';
import 'package:local_legends/utils/validators.dart';

/// Log in accepts a username OR an email.
void main() {
  group('AuthService.looksLikeEmail', () {
    test('emails', () {
      expect(AuthService.looksLikeEmail('juan@mail.com'), isTrue);
      expect(AuthService.looksLikeEmail('  testlegend@locallegends.test '), isTrue);
    });
    test('usernames, with or without a leading @', () {
      expect(AuthService.looksLikeEmail('testlegend'), isFalse);
      expect(AuthService.looksLikeEmail('@testlegend'), isFalse);
    });
  });

  group('Validators.usernameOrEmail', () {
    test('accepts a username', () {
      expect(Validators.usernameOrEmail('testlegend'), isNull);
      expect(Validators.usernameOrEmail('@TestLegend'), isNull);
    });
    test('accepts an email', () {
      expect(Validators.usernameOrEmail('testlegend@locallegends.test'), isNull);
    });
    test('rejects empty, a bad email, and a bad username', () {
      expect(Validators.usernameOrEmail(''), 'Enter your username or email.');
      expect(Validators.usernameOrEmail('juan@mail'), 'Enter a valid email address.');
      expect(Validators.usernameOrEmail('ab'), isNotNull);
    });
  });
}
