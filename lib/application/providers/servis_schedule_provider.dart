import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

// ============================================
// FILOSOFI BARU (SESUAI BUKU SERVIS HONDA):
// ============================================
// SEMUA service memiliki DUA trigger: KM dan WAKTU (bulan)
// Servis dilakukan berdasarkan "MANA YANG TERCAPAI LEBIH DULU"
//
// Contoh: Oli Mesin - Servis 2
//   - KM: 4000 km
//   - Waktu: 4 bulan
//   - Action: Ganti
//
// Jika user mencapai 4000 km dalam 2 bulan -> Servis sekarang (KM tercapai)
// Jika user baru 2000 km tapi sudah 4 bulan -> Servis sekarang (Waktu tercapai)
// ============================================

/// Model untuk satu entry schedule (satu milestone servis)
class ScheduleEntry {
  final String action; // "Ganti" atau "Periksa"
  final int km; // Kilometer milestone
  final int months; // Waktu dalam bulan

  ScheduleEntry({
    required this.action,
    required this.km,
    required this.months,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      action: json['action'] ?? '',
      km: json['km'] ?? 0,
      months: json['months'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'km': km,
      'months': months,
    };
  }
}

/// Model untuk service item dengan schedule lengkap (KM + Waktu)
class ServiceItem {
  final String component; // Nama komponen (Oli Mesin, Busi, dll)
  final String note; // Catatan (*1, *2, dll)
  final Map<String, ScheduleEntry> schedule; // key: km (string), value: ScheduleEntry

  ServiceItem({
    required this.component,
    required this.note,
    required this.schedule,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    // Parse schedule map
    final scheduleMap = <String, ScheduleEntry>{};
    final scheduleData = json['schedule'] as Map<String, dynamic>?;

    if (scheduleData != null) {
      scheduleData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          scheduleMap[key] = ScheduleEntry.fromJson(value);
        }
      });
    }

    return ServiceItem(
      component: json['component'] ?? '',
      note: json['note'] ?? '',
      schedule: scheduleMap,
    );
  }

  /// Get sorted list of schedule entries by KM
  List<MapEntry<String, ScheduleEntry>> getSortedSchedule() {
    final entries = schedule.entries.toList();
    entries.sort((a, b) => a.value.km.compareTo(b.value.km));
    return entries;
  }

  List<int> getKmMilestones() {
    return schedule.values.map((e) => e.km).toList()..sort();
  }

  List<int> getMonthMilestones() {
    return schedule.values.map((e) => e.months).toList()..sort();
  }

  int? detectServiceInterval() {
    final milestones = getKmMilestones();
    if (milestones.length < 3) return null;

    final intervals = <int, int>{};
    for (int i = 1; i < milestones.length; i++) {
      final interval = milestones[i] - milestones[i - 1];
      intervals[interval] = (intervals[interval] ?? 0) + 1;
    }

    if (intervals.isEmpty) return null;

    final sortedIntervals = intervals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedIntervals.first.key;
  }

  /// Check if this service has any "Ganti" action
  bool hasReplacementAction() {
    return schedule.values.any((entry) => entry.action.contains('Ganti'));
  }

  /// Check if this service has any "Periksa" action
  bool hasInspectionAction() {
    return schedule.values.any((entry) => entry.action.contains('Periksa'));
  }
}

/// Model untuk motor schedule lengkap
class MotorServiceSchedule {
  final String motorName;
  final String model;
  final String category;
  final String brand;
  final List<ServiceItem> services;

  MotorServiceSchedule({
    required this.motorName,
    required this.model,
    required this.category,
    required this.brand,
    required this.services,
  });

  factory MotorServiceSchedule.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List?)
            ?.map((service) {
              try {
                return ServiceItem.fromJson(service);
              } catch (e) {
                return null;
              }
            })
            .whereType<ServiceItem>()
            .toList() ??
        [];

    return MotorServiceSchedule(
      motorName: json['motor_name'] ?? '',
      model: json['model'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      services: servicesList,
    );
  }
}

/// Result dari kalkulasi next service
class NextServiceInfo {
  final ScheduleEntry nextService;
  final double kmProgress; // 0.0 - 1.0 (progress berdasarkan KM)
  final double timeProgress; // 0.0 - 1.0 (progress berdasarkan waktu)
  final double overallProgress; // Max dari kmProgress dan timeProgress
  final int currentKm; // Current odometer distance
  final int monthsSinceStart; // Bulan sejak motor ditambahkan
  final String triggerType; // "km" atau "time" atau "both" (mana yang lebih dulu/dekat)

  NextServiceInfo({
    required this.nextService,
    required this.kmProgress,
    required this.timeProgress,
    required this.overallProgress,
    required this.currentKm,
    required this.monthsSinceStart,
    required this.triggerType,
  });

  /// Check if service is due (sudah waktunya servis)
  bool isDue() {
    return overallProgress >= 0.95; // 95% atau lebih
  }

  /// Get progress percentage (0-100)
  int getProgressPercentage() {
    return (overallProgress * 100).round().clamp(0, 100);
  }
}

/// Helper class untuk kalkulasi progress servis
class ServiceProgressCalculator {
  /// Hitung next service dan progress berdasarkan KM dan Waktu
  /// Time dihitung dari estimated reference date (tanggalBeli)
  /// "Mana yang tercapai lebih dulu" - KM atau Time
  static NextServiceInfo? calculateNextService({
    required ServiceItem serviceItem,
    required int currentOdometer,
    required int initialOdometer,
    required DateTime motorPurchaseDate,
    DateTime? lastServiceDate,
    int? lastServiceOdometer,
  }) {
    if (serviceItem.schedule.isEmpty) {
      return null;
    }

    final sortedSchedule = serviceItem.getSortedSchedule();
    final now = DateTime.now();

    final referenceDate = lastServiceDate ?? motorPurchaseDate;
    final totalMonthsFromReference = _calculateMonthsDifference(referenceDate, now);

    ScheduleEntry? nextServiceEntry;
    ScheduleEntry? previousServiceEntry;
    int? detectedInterval = serviceItem.detectServiceInterval();

    if (lastServiceOdometer != null && lastServiceOdometer > 0) {
      bool foundNext = false;
      for (var entry in sortedSchedule) {
        if (entry.value.km > lastServiceOdometer) {
          if (!foundNext) {
            nextServiceEntry = entry.value;
            foundNext = true;
          }
          break;
        }
        previousServiceEntry = entry.value;
      }

      if (nextServiceEntry == null && detectedInterval != null) {
        final lastScheduleEntry = sortedSchedule.last.value;
        int calculatedNextKm = lastScheduleEntry.km;

        while (calculatedNextKm <= lastServiceOdometer) {
          calculatedNextKm += detectedInterval;
        }

        nextServiceEntry = ScheduleEntry(
          action: lastScheduleEntry.action,
          km: calculatedNextKm,
          months: lastScheduleEntry.months,
        );
        previousServiceEntry = ScheduleEntry(
          action: lastScheduleEntry.action,
          km: calculatedNextKm - detectedInterval,
          months: lastScheduleEntry.months,
        );
      } else if (nextServiceEntry == null) {
        nextServiceEntry = sortedSchedule.last.value;
        previousServiceEntry = sortedSchedule.length > 1
            ? sortedSchedule[sortedSchedule.length - 2].value
            : null;
      }
    } else {
      for (var entry in sortedSchedule) {
        if (currentOdometer < entry.value.km) {
          nextServiceEntry = entry.value;
          break;
        }
        previousServiceEntry = entry.value;
      }

      if (nextServiceEntry == null && detectedInterval != null) {
        final lastScheduleEntry = sortedSchedule.last.value;
        int calculatedNextKm = lastScheduleEntry.km;

        while (calculatedNextKm <= currentOdometer) {
          calculatedNextKm += detectedInterval;
        }

        nextServiceEntry = ScheduleEntry(
          action: lastScheduleEntry.action,
          km: calculatedNextKm,
          months: lastScheduleEntry.months,
        );
        previousServiceEntry = ScheduleEntry(
          action: lastScheduleEntry.action,
          km: calculatedNextKm - detectedInterval,
          months: lastScheduleEntry.months,
        );
      } else if (nextServiceEntry == null) {
        nextServiceEntry = sortedSchedule.last.value;
        previousServiceEntry = sortedSchedule.length > 1
            ? sortedSchedule[sortedSchedule.length - 2].value
            : null;
      }
    }

    final previousKm = lastServiceOdometer ?? previousServiceEntry?.km ?? 0;
    final nextKm = nextServiceEntry.km;
    final kmRange = nextKm - previousKm;
    final currentKmInRange = currentOdometer - previousKm;
    final kmProgress = kmRange > 0
        ? (currentKmInRange / kmRange).clamp(0.0, 1.0)
        : 0.0;

    final previousMonths = previousServiceEntry?.months ?? 0;
    final nextMonths = nextServiceEntry.months;
    final monthsRange = lastServiceDate != null
        ? nextMonths
        : nextMonths - previousMonths;
    final timeProgress = monthsRange > 0
        ? (totalMonthsFromReference / monthsRange).clamp(0.0, 1.0)
        : 0.0;

    final overallProgress = kmProgress > timeProgress ? kmProgress : timeProgress;

    String triggerType;
    if ((kmProgress - timeProgress).abs() < 0.1) {
      triggerType = 'both';
    } else if (kmProgress > timeProgress) {
      triggerType = 'km';
    } else {
      triggerType = 'time';
    }

    return NextServiceInfo(
      nextService: nextServiceEntry,
      kmProgress: kmProgress,
      timeProgress: timeProgress,
      overallProgress: overallProgress,
      currentKm: currentOdometer,
      monthsSinceStart: totalMonthsFromReference,
      triggerType: triggerType,
    );
  }

  static int _calculateMonthsDifference(DateTime start, DateTime end) {
    int months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) {
      months--;
    }
    return months.clamp(0, 9999);
  }
}

// Provider untuk fetch servis schedule berdasarkan motor model/type
final servisScheduleProvider = FutureProvider.family<MotorServiceSchedule?, String>(
  (ref, motorModel) async {
    debugPrint('🔍 [SCHEDULE] servisScheduleProvider called for: $motorModel');

    try {
      final firestore = FirebaseFirestore.instance;

      // Direct query ke collection 'motors'
      try {
        debugPrint('📡 [SCHEDULE] Fetching from Firestore collection: motors');
        final snapshot = await firestore.collection('motors').get();
        debugPrint('📦 [SCHEDULE] Got ${snapshot.docs.length} documents from Firestore');

        if (snapshot.docs.isNotEmpty) {
          // Search untuk motor yang cocok dengan motorModel (case insensitive)
          final motorModelLower = motorModel.toLowerCase();
          debugPrint('🔎 [SCHEDULE] Searching for model: "$motorModelLower"');

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final category = (data['category'] as String?)?.toLowerCase() ?? '';
            final motorName = (data['motor_name'] as String?)?.toLowerCase() ?? '';
            final model = (data['model'] as String?)?.toLowerCase() ?? '';

            debugPrint('📋 [SCHEDULE] Checking doc: category="$category", motorName="$motorName", model="$model"');

            // Match berdasarkan category atau motor_name (case insensitive)
            if (category == motorModelLower ||
                motorName.contains(motorModelLower) ||
                motorModelLower.contains(motorName.split(',')[0].trim())) {
              debugPrint('✅ [SCHEDULE] MATCH FOUND! Parsing schedule...');

              try {
                final schedule = MotorServiceSchedule.fromJson(data);
                debugPrint('✅ [SCHEDULE] Schedule parsed successfully: ${schedule.services.length} services');
                return schedule;
              } catch (e) {
                debugPrint('❌ [SCHEDULE] Error parsing schedule: $e');
                return null;
              }
            }
          }

          debugPrint('⚠️ [SCHEDULE] No match found for "$motorModelLower"');
        } else {
          debugPrint('⚠️ [SCHEDULE] No documents in motors collection');
        }
      } catch (e) {
        debugPrint('❌ [SCHEDULE] Error fetching from Firestore: $e');
      }

      debugPrint('❌ [SCHEDULE] Returning null (no schedule found)');
      return null;
    } catch (e) {
      debugPrint('❌ [SCHEDULE] Exception in provider: $e');
      return null;
    }
  },
);
