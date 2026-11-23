/// Pure functions so they can be unit tested without Firebase.
/// Each returns null when valid, or an error message when invalid.
class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  /// 3 to 20 characters: letters, numbers, underscore. A leading @ is
  /// ignored and capitals are lower-cased before checking.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a username.';
    final handle = value.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (handle.length < 3) return 'Username must be at least 3 characters.';
    if (handle.length > 20) return 'Username can be at most 20 characters.';
    if (!_usernamePattern.hasMatch(handle)) {
      return 'Use only letters, numbers, and underscores.';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your name.';
    if (value.trim().length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }
}
