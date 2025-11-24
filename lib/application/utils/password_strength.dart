import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

enum PasswordStrength {
  empty,
  weak,
  medium,
  strong,
}

class PasswordStrengthHelper {
  static PasswordStrength checkStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Check length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Check for lowercase
    if (password.contains(RegExp(r'[a-z]'))) score++;

    // Check for uppercase
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Check for digits
    if (password.contains(RegExp(r'[0-9]'))) score++;

    // Check for special characters
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) {
      return PasswordStrength.weak;
    } else if (score <= 4) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.strong;
    }
  }

  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Lemah';
      case PasswordStrength.medium:
        return 'Sedang';
      case PasswordStrength.strong:
        return 'Kuat';
    }
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return AppColors.neutral300;
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return const Color(0xFFFF9800); // Orange
      case PasswordStrength.strong:
        return const Color(0xFF4CAF50); // Green
    }
  }

  static double getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return 0.0;
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  static List<String> getPasswordRequirements(String password) {
    final List<String> requirements = [];

    if (password.length < 8) {
      requirements.add('Minimal 8 karakter');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      requirements.add('Gunakan huruf besar');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      requirements.add('Gunakan huruf kecil');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      requirements.add('Gunakan angka');
    }

    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      requirements.add('Gunakan karakter spesial (!@#\$%...)');
    }

    return requirements;
  }
}
