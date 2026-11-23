import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thrown for username problems Firebase Auth itself doesn't know about.
class UsernameException implements Exception {
  const UsernameException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around Firebase Authentication (black-box reuse).
///
/// Users log in with their USERNAME or their EMAIL.
/// Firebase Auth only signs in with email, so for usernames Firestore
/// keeps a lookup:
///   usernames/{username} -> { uid, email }
///   users/{uid}          -> { username, displayName, email, createdAt }
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// "@Juan_Explores " -> "juan_explores"
  static String normalizeUsername(String value) =>
      value.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

  DocumentReference<Map<String, dynamic>> _usernameDoc(String username) =>
      _db.collection('usernames').doc(normalizeUsername(username));

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _usernameDoc(username).get();
    return !doc.exists;
  }

  /// True for "juan@mail.com", false for "juan_explores" or "@juan".
  static bool looksLikeEmail(String value) {
    final v = value.trim();
    return v.indexOf('@') > 0;
  }

  /// An email is used as is; a username is looked up in Firestore.
  Future<String> _emailFor(String usernameOrEmail) async {
    if (looksLikeEmail(usernameOrEmail)) return usernameOrEmail.trim();
    return _emailForUsername(usernameOrEmail);
  }

  Future<String> _emailForUsername(String username) async {
    final doc = await _usernameDoc(username).get();
    final email = doc.data()?['email'] as String?;
    if (email == null) {
      // Same wording as a wrong password, so nobody can probe which
      // usernames exist.
      throw FirebaseAuthException(code: 'user-not-found');
    }
    return email;
  }

  Future<String?> fetchUsername(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['username'] as String?;
  }

  Future<void> signUp({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    final handle = normalizeUsername(username);
    if (!await isUsernameAvailable(handle)) {
      throw const UsernameException('That username is already taken.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    try {
      await _db.runTransaction((tx) async {
        final nameRef = _usernameDoc(handle);
        if ((await tx.get(nameRef)).exists) {
          throw const UsernameException('That username was just taken.');
        }
        tx.set(nameRef, {'uid': user.uid, 'email': email.trim()});
        tx.set(_db.collection('users').doc(user.uid), {
          'username': handle,
          'displayName': name.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      await user.updateDisplayName(name.trim());
    } catch (_) {
      // Don't leave an Auth account with no username behind.
      await user.delete();
      rethrow;
    }
  }

  /// [usernameOrEmail] can be "juan_explores", "@juan_explores" or
  /// "juan@mail.com".
  Future<void> signIn({required String usernameOrEmail, required String password}) async {
    final email = await _emailFor(usernameOrEmail);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String usernameOrEmail) async {
    final email = await _emailFor(usernameOrEmail);
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();
}
