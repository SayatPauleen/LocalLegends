import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

enum _NameCheck { idle, checking, available, taken }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidePassword = true;
  _NameCheck _nameCheck = _NameCheck.idle;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Checks availability 0.5 s after the user stops typing.
  void _onUsernameChanged(String value) {
    final auth = context.read<AuthProvider>()..clearError();
    _debounce?.cancel();
    if (Validators.username(value) != null) {
      setState(() => _nameCheck = _NameCheck.idle);
      return;
    }
    setState(() => _nameCheck = _NameCheck.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final free = await auth.isUsernameAvailable(value);
        if (!mounted || _username.text != value) return;
        setState(() => _nameCheck = free ? _NameCheck.available : _NameCheck.taken);
      } catch (_) {
        if (mounted) setState(() => _nameCheck = _NameCheck.idle);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context
        .read<AuthProvider>()
        .signUp(_username.text, _name.text, _email.text, _password.text);
    if (ok && mounted) {
      // Remove this screen so AuthGate (now showing Home) is visible.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget? _usernameSuffix() {
    switch (_nameCheck) {
      case _NameCheck.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _NameCheck.available:
        return const Icon(Icons.check_circle_outline, color: AppColors.teal);
      case _NameCheck.taken:
        return Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error);
      case _NameCheck.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        backgroundColor: Colors.transparent,
      ),
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
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      onChanged: _onUsernameChanged,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        helperText: _nameCheck == _NameCheck.available
                            ? 'Available'
                            : '3 to 20 letters, numbers, or underscores. You log in with this.',
                        suffixIcon: _usernameSuffix(),
                      ),
                      validator: (v) {
                        final error = Validators.username(v);
                        if (error != null) return error;
                        if (_nameCheck == _NameCheck.taken) {
                          return 'That username is already taken.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        helperText: 'Only used to reset your password.',
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: '8+ characters with a letter and a number',
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
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                      validator: (v) =>
                          Validators.confirmPassword(v, _password.text),
                    ),
                    const SizedBox(height: 20),
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
                          : const Text('Create account'),
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
