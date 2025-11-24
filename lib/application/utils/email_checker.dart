enum EmailStatus {
  initial,
  checking,
  available,
  taken,
  invalid,
}

class EmailChecker {
  /// Check apakah email sudah terdaftar di Firebase
  static Future<EmailStatus> checkEmailAvailability(String email) async {
    if (email.isEmpty) {
      return EmailStatus.initial;
    }

    if (!_isValidEmail(email)) {
      return EmailStatus.invalid;
    }

    return EmailStatus.available;
  }

  /// Validasi format email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Get message berdasarkan status
  static String getStatusMessage(EmailStatus status) {
    switch (status) {
      case EmailStatus.initial:
        return '';
      case EmailStatus.checking:
        return 'Memeriksa email...';
      case EmailStatus.available:
        return 'Email tersedia';
      case EmailStatus.taken:
        return 'Email sudah terdaftar';
      case EmailStatus.invalid:
        return 'Format email tidak valid';
    }
  }
}
