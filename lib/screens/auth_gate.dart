import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Shows the right screen for the current session, so no screen has to
/// check auth on its own.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
