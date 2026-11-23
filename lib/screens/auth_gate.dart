import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import 'home_shell.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';

enum _Stage { welcome, onboarding, login }

/// Shows the right screen for the current session, so no screen has to
/// check auth on its own.
///
/// Revision 2 flow:
///   app start -> Splash (at least 1.2 s)
///     logged in  -> HomeShell
///     logged out -> Splash with "Let's explore"
///                     -> Onboarding (first time only) -> Sign up / Log in
///                   "I already have an account" -> Log in
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _onboardingSeenKey = 'onboardingSeen';

  _Stage _stage = _Stage.welcome;
  bool _minSplashDone = false;

  @override
  void initState() {
    super.initState();
    // Keep the splash up briefly so it doesn't just flash.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  Future<void> _explore() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_onboardingSeenKey) ?? false;
    if (!mounted) return;
    setState(() => _stage = seen ? _Stage.login : _Stage.onboarding);
  }

  Future<void> _finishOnboarding({required bool openSignup}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    if (!mounted) return;
    setState(() => _stage = _Stage.login);
    if (openSignup) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (!_minSplashDone || status == AuthStatus.unknown) {
      return const SplashScreen();
    }
    if (status == AuthStatus.authenticated) {
      return const HomeShell();
    }

    switch (_stage) {
      case _Stage.welcome:
        return SplashScreen(
          onExplore: _explore,
          onHaveAccount: () => setState(() => _stage = _Stage.login),
        );
      case _Stage.onboarding:
        return OnboardingScreen(
          onFinish: () => _finishOnboarding(openSignup: true),
          onSkip: () => _finishOnboarding(openSignup: false),
        );
      case _Stage.login:
        return const LoginScreen();
    }
  }
}
