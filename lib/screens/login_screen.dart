import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController(); // username or email
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // On success, AuthGate switches screens by itself.
    await context.read<AuthProvider>().signIn(_login.text, _password.text);
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    if (Validators.usernameOrEmail(_login.text) != null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Enter your username or email first, then tap Forgot password.'),
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_login.text);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'Reset link sent to the email on this account.'
          : auth.errorMessage ?? 'Could not send reset link.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'LocalLegends',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Log in with your username or email to find the hidden gems in your neighborhood.',
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _login,
                      autocorrect: false,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username or email',
                        hintText: 'juan_explores or juan@mail.com',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.usernameOrEmail,
                      onChanged: (_) => auth.clearError(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip:
                              _hidePassword ? 'Show password' : 'Hide password',
                          icon: Icon(_hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your password.'
                          : null,
                      onChanged: (_) => auth.clearError(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isLoading ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (auth.errorMessage != null) ...[
                      Text(
                        auth.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              auth.clearError();
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ));
                            },
                      child: const Text('New here? Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
