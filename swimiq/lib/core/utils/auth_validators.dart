/// Form validation helpers for auth screens.
abstract final class AuthValidators {
  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }
}

/// Maps Supabase auth errors to user-friendly messages.
abstract final class AuthErrorMapper {
  static String fromException(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password')) {
      return 'Password does not meet requirements.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Network error. Check your connection and try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
