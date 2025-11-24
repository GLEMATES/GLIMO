// Service Rules Decision Support System (DSS)
// Berdasarkan Honda Service Schedule Manual
//
// Sistem 4-level urgency untuk maintenance prediction:
// - 🟢 AMAN (<70%): Kondisi normal
// - 🟡 PERINGATAN (70-90%): Persiapkan servis
// - 🟠 WAJIB SERVIS (90-100%): Sudah waktunya servis
// - 🔴 TERLAMBAT (>100%): Terlambat servis, segera ke bengkel

enum ServiceUrgency {
  safe,     // 🟢 <70% - Masih aman
  warning,  // 🟡 70-90% - Segera siapkan servis
  urgent,   // 🟠 90-100% - Wajib servis sekarang
  critical, // 🔴 >100% - Terlambat servis
}

class ServiceUrgencyInfo {
  final ServiceUrgency urgency;
  final String emoji;
  final String status;
  final String message;
  final String color; // Hex color for UI

  ServiceUrgencyInfo({
    required this.urgency,
    required this.emoji,
    required this.status,
    required this.message,
    required this.color,
  });
}

class ServiceRulesDSS {
  static ServiceUrgencyInfo calculateUrgency({
    required double progressPercentage,
    required int kmRemaining,
    required String componentName,
    required String action,
  }) {
    final ServiceUrgency urgency;
    final String emoji;
    final String status;
    final String message;
    final String color;

    final actionVerb = action.toLowerCase().contains('ganti') ? 'ganti' : 'periksa';

    if (progressPercentage >= 100) {
      urgency = ServiceUrgency.critical;
      emoji = '🔴';
      status = 'TERLAMBAT';
      final overKm = kmRemaining.abs();
      message = 'URGENT: $componentName terlambat $actionVerb $overKm km! Segera ke bengkel.';
      color = '#D32F2F';
    } else if (progressPercentage >= 90) {
      urgency = ServiceUrgency.urgent;
      emoji = '🟠';
      status = 'WAJIB SERVIS';
      message = 'Waktunya $actionVerb $componentName! Tersisa $kmRemaining km.';
      color = '#F57C00';
    } else if (progressPercentage >= 70) {
      urgency = ServiceUrgency.warning;
      emoji = '🟡';
      status = 'PERINGATAN';
      message = '$componentName segera perlu $actionVerb. Tersisa $kmRemaining km.';
      color = '#FBC02D';
    } else {
      urgency = ServiceUrgency.safe;
      emoji = '🟢';
      status = 'AMAN';
      message = 'Masih aman. Servis berikutnya $kmRemaining km lagi.';
      color = '#388E3C';
    }

    return ServiceUrgencyInfo(
      urgency: urgency,
      emoji: emoji,
      status: status,
      message: message,
      color: color,
    );
  }

  /// Get all components with urgency level >= warning
  /// Used for filtering components that need attention
  static bool needsAttention(ServiceUrgency urgency) {
    return urgency == ServiceUrgency.warning ||
        urgency == ServiceUrgency.urgent ||
        urgency == ServiceUrgency.critical;
  }

  /// Get priority score for sorting (higher = more urgent)
  static int getPriorityScore(ServiceUrgency urgency) {
    switch (urgency) {
      case ServiceUrgency.critical:
        return 4;
      case ServiceUrgency.urgent:
        return 3;
      case ServiceUrgency.warning:
        return 2;
      case ServiceUrgency.safe:
        return 1;
    }
  }

  /// Check if notification should be sent for this urgency level
  static bool shouldNotify(ServiceUrgency urgency) {
    // Send notification for warning, urgent, and critical
    return urgency != ServiceUrgency.safe;
  }

  /// Get notification title based on urgency
  static String getNotificationTitle(ServiceUrgency urgency, String componentName) {
    switch (urgency) {
      case ServiceUrgency.critical:
        return '🔴 URGENT: $componentName Terlambat Servis!';
      case ServiceUrgency.urgent:
        return '🟠 Waktunya Servis $componentName';
      case ServiceUrgency.warning:
        return '🟡 Peringatan: $componentName Perlu Servis';
      case ServiceUrgency.safe:
        return '$componentName Masih Aman';
    }
  }

  /// Get notification body based on urgency
  static String getNotificationBody(ServiceUrgencyInfo info) {
    return info.message;
  }
}
