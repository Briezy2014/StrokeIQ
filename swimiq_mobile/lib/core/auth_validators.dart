/// Simple helper for auth form validation messages.
class AuthValidators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!email.contains('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? swimmerName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Swimmer name or code is required.';
    }
    return null;
  }
}
