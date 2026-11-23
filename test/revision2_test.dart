import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_legends/screens/onboarding_screen.dart';
import 'package:local_legends/screens/splash_screen.dart';
import 'package:local_legends/services/auth_service.dart';
import 'package:local_legends/theme/app_theme.dart';
import 'package:local_legends/utils/validators.dart';

void main() {
  group('Validators.username', () {
    test('accepts letters, numbers, underscore (3 to 20)', () {
      expect(Validators.username('juan_explores'), isNull);
      expect(Validators.username('abc'), isNull);
    });
    test('ignores a leading @ and capitals', () {
      expect(Validators.username('@Juan_Explores'), isNull);
    });
    test('rejects empty, too short, too long, and symbols', () {
      expect(Validators.username(''), isNotNull);
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('a' * 21), isNotNull);
      expect(Validators.username('juan.explores'), isNotNull);
      expect(Validators.username('juan explores'), isNotNull);
    });
    test('the test account testlegend / legend123 passes the sign-up rules', () {
      expect(Validators.username('testlegend'), isNull);
      expect(Validators.password('legend123'), isNull);
    });
  });

  test('normalizeUsername trims, drops @, lower-cases', () {
    expect(AuthService.normalizeUsername('  @Test_Legend '), 'test_legend');
  });

  Widget wrap(Widget child) => MaterialApp(theme: buildAppTheme(), home: child);

  testWidgets('splash hides buttons while loading', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    expect(find.text('LocalLegends'), findsOneWidget);
    expect(find.text('Let’s explore'), findsNothing);
  });

  testWidgets('splash shows Let’s explore when logged out', (tester) async {
    var explored = false;
    await tester.pumpWidget(wrap(SplashScreen(
      onExplore: () => explored = true,
      onHaveAccount: () {},
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Let’s explore'));
    expect(explored, isTrue);
  });

  testWidgets('onboarding: Next twice, then Find my local legends', (tester) async {
    var finished = false;
    await tester.pumpWidget(wrap(OnboardingScreen(
      onFinish: () => finished = true,
      onSkip: () {},
    )));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Find my local legends'), findsOneWidget);
    await tester.tap(find.text('Find my local legends'));
    expect(finished, isTrue);
  });
}
