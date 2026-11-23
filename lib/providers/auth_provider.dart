import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide auth state (Provider, architectural reuse).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _subscription = _service.authStateChanges.listen((user) {
      _user = user;
      _username = null;
      _status =
          user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
      if (user != null) _loadUsername(user.uid);
    });
  }

  final AuthService _service;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _username;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadUsername(String uid) async {
    try {
      _username = await _service.fetchUsername(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load username: $e');
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String username, String password) {
    return _run(() => _service.signIn(username: username, password: password));
  }

  Future<bool> signUp(String username, String name, String email, String password) {
    return _run(
      () => _service.signUp(
        username: username,
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> isUsernameAvailable(String username) =>
      _service.isUsernameAvailable(username);

  Future<bool> sendPasswordReset(String username) {
    return _run(() => _service.sendPasswordReset(username));
  }

  Future<void> signOut() => _service.signOut();

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on UsernameException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error: ${e.code} ${e.message}');
      _errorMessage = messageForCode(e.code);
      return false;
    } on FirebaseException catch (e) {
      // Firestore errors (username lookup), e.g. permission-denied.
      debugPrint('Firestore error: ${e.code} ${e.message}');
      _errorMessage = messageForCode(e.code);
      return false;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  static String messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect username or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'permission-denied':
        return 'Firestore rules blocked this. Check firestore.rules.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
