import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Model untuk satu record riwayat servis
class ServiceHistory {
  final String id; // Unique ID untuk setiap record
  final String motorId; // ID motor yang di-servis
  final String motorName; // Nama motor (untuk display)
  final String serviceName; // Nama servis (Oli Mesin, Filter, dll)
  final String serviceType; // Jenis action: "Ganti" atau "Periksa"
  final int odometer; // Odometer saat servis
  final DateTime date; // Tanggal servis

  ServiceHistory({
    required this.id,
    required this.motorId,
    required this.motorName,
    required this.serviceName,
    required this.serviceType,
    required this.odometer,
    required this.date,
  });

  /// Get relative time string (e.g., "4 bulan lalu", "2 hari lalu")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Baru saja';
      }
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Convert ke JSON untuk disimpan di SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motorId': motorId,
      'motorName': motorName,
      'serviceName': serviceName,
      'serviceType': serviceType,
      'odometer': odometer,
      'date': date.toIso8601String(),
    };
  }

  /// Create dari JSON
  factory ServiceHistory.fromJson(Map<String, dynamic> json) {
    return ServiceHistory(
      id: json['id'] ?? '',
      motorId: json['motorId'] ?? '',
      motorName: json['motorName'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceType: json['serviceType'] ?? '',
      odometer: json['odometer'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

/// Model untuk grouping servis berdasarkan component
class ComponentServiceGroup {
  final String componentName; // Nama komponen (Oli Mesin, Busi, dll)
  final ServiceHistory? lastGanti; // Servis terakhir dengan action "Ganti"
  final ServiceHistory? lastPeriksa; // Servis terakhir dengan action "Periksa"
  final int totalGanti; // Total berapa kali diganti
  final int totalPeriksa; // Total berapa kali diperiksa
  final List<ServiceHistory> allHistory; // Semua history untuk component ini (sorted by date desc)

  ComponentServiceGroup({
    required this.componentName,
    this.lastGanti,
    this.lastPeriksa,
    required this.totalGanti,
    required this.totalPeriksa,
    required this.allHistory,
  });

  /// Get the most recent service (either Ganti or Periksa)
  ServiceHistory? getMostRecentService() {
    if (lastGanti == null && lastPeriksa == null) return null;
    if (lastGanti == null) return lastPeriksa;
    if (lastPeriksa == null) return lastGanti;
    return lastGanti!.date.isAfter(lastPeriksa!.date) ? lastGanti : lastPeriksa;
  }

  /// Get total count of all services (Ganti + Periksa)
  int getTotalServices() {
    return totalGanti + totalPeriksa;
  }
}

/// Notifier untuk manage riwayat servis
class ServiceHistoryNotifier extends Notifier<List<ServiceHistory>> {
  StreamSubscription<QuerySnapshot>? _subscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  List<ServiceHistory> build() {
    _loadHistory();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return [];
  }

  /// Load riwayat dari Firestore dengan realtime updates
  Future<void> _loadHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = [];
        return;
      }

      await _migrateFromLocalToFirestore();

      _subscription?.cancel();
      _subscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('service_history')
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
        final histories = snapshot.docs.map((doc) {
          final data = doc.data();
          return ServiceHistory(
            id: doc.id,
            motorId: data['motorId'] ?? '',
            motorName: data['motorName'] ?? '',
            serviceName: data['serviceName'] ?? '',
            serviceType: data['serviceType'] ?? '',
            odometer: data['odometer'] ?? 0,
            date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        state = histories;
      });
    } catch (e) {
      state = [];
    }
  }

  /// Migrate data dari SharedPreferences ke Firestore (one-time)
  Future<void> _migrateFromLocalToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('service_history_${user.uid}');

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        final localHistories = decoded.map((json) => ServiceHistory.fromJson(json)).toList();

        if (localHistories.isEmpty) {
          await prefs.remove('service_history_${user.uid}');
          return;
        }

        final batch = _firestore.batch();

        for (var history in localHistories) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('service_history')
              .doc(history.id);

          batch.set(docRef, {
            'motorId': history.motorId,
            'motorName': history.motorName,
            'serviceName': history.serviceName,
            'serviceType': history.serviceType,
            'odometer': history.odometer,
            'date': Timestamp.fromDate(history.date),
          });
        }

        await batch.commit();
        await prefs.remove('service_history_${user.uid}');
      }
    } catch (e) {
      // Error migrating, will retry next time
    }
  }

  /// Tambah riwayat servis baru
  Future<void> addServiceHistory({
    required String motorId,
    required String motorName,
    required String serviceName,
    required String serviceType,
    required int odometer,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final id = now.millisecondsSinceEpoch.toString();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('service_history')
          .doc(id)
          .set({
        'motorId': motorId,
        'motorName': motorName,
        'serviceName': serviceName,
        'serviceType': serviceType,
        'odometer': odometer,
        'date': Timestamp.fromDate(now),
      });
    } catch (e) {
      // Error adding history
    }
  }

  /// Get riwayat berdasarkan tanggal
  List<ServiceHistory> getHistoryByDate(DateTime date) {
    return state.where((h) {
      return h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day;
    }).toList();
  }

  /// Get daftar tanggal unik (untuk group by date)
  List<DateTime> getUniqueDates() {
    final dates = <DateTime>{};

    for (var history in state) {
      final normalizedDate = DateTime(history.date.year, history.date.month, history.date.day);
      dates.add(normalizedDate);
    }

    // Sort from newest to oldest
    final sortedDates = dates.toList();
    sortedDates.sort((a, b) => b.compareTo(a));

    return sortedDates;
  }

  /// Get riwayat berdasarkan motor
  List<ServiceHistory> getHistoryByMotor(String motorId) {
    return state.where((h) => h.motorId == motorId).toList();
  }

  /// Get riwayat berdasarkan component name
  List<ServiceHistory> getHistoryByComponent(String componentName) {
    return state.where((h) => h.serviceName == componentName).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  /// Get grouped services by component
  List<ComponentServiceGroup> getGroupedByComponent() {
    // Get unique component names
    final componentNames = <String>{};
    for (var history in state) {
      componentNames.add(history.serviceName);
    }

    // Create groups
    final groups = <ComponentServiceGroup>[];
    for (var componentName in componentNames) {
      final componentHistory = getHistoryByComponent(componentName);

      if (componentHistory.isEmpty) continue;

      // Find last Ganti and last Periksa
      ServiceHistory? lastGanti;
      ServiceHistory? lastPeriksa;
      int totalGanti = 0;
      int totalPeriksa = 0;

      for (var history in componentHistory) {
        if (history.serviceType.contains('Ganti')) {
          totalGanti++;
          if (lastGanti == null || history.date.isAfter(lastGanti.date)) {
            lastGanti = history;
          }
        } else if (history.serviceType.contains('Periksa')) {
          totalPeriksa++;
          if (lastPeriksa == null || history.date.isAfter(lastPeriksa.date)) {
            lastPeriksa = history;
          }
        }
      }

      groups.add(ComponentServiceGroup(
        componentName: componentName,
        lastGanti: lastGanti,
        lastPeriksa: lastPeriksa,
        totalGanti: totalGanti,
        totalPeriksa: totalPeriksa,
        allHistory: componentHistory,
      ));
    }

    // Sort by most recent service
    groups.sort((a, b) {
      final aRecent = a.getMostRecentService()?.date;
      final bRecent = b.getMostRecentService()?.date;
      if (aRecent == null && bRecent == null) return 0;
      if (aRecent == null) return 1;
      if (bRecent == null) return -1;
      return bRecent.compareTo(aRecent);
    });

    return groups;
  }

  /// Delete riwayat berdasarkan ID
  Future<void> deleteHistory(String historyId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('service_history')
          .doc(historyId)
          .delete();
    } catch (e) {
      // Error deleting history
    }
  }

  /// Auto-generate past service histories berdasarkan odometer saat motor ditambahkan
  /// Ini akan men-detect KPB mana yang sudah terlewati dan auto-create service history
  Future<void> autoGeneratePastServices({
    required String motorId,
    required String motorName,
    required int currentOdometer,
    required DateTime motorPurchaseDate,
    required Map<String, dynamic> serviceSchedule, // Service schedule dari Firestore
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      // Parse service items dari schedule
      final servicesList = (serviceSchedule['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // List untuk batch write
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      final now = DateTime.now();
      int idCounter = 0; // Counter untuk unique ID

      for (var serviceData in servicesList) {
        final component = serviceData['component'] as String? ?? '';
        if (component.isEmpty) continue;

        final scheduleMap = serviceData['schedule'] as Map<String, dynamic>? ?? {};

        // Sort milestones by KM
        final milestones = <MapEntry<String, Map<String, dynamic>>>[];
        scheduleMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            milestones.add(MapEntry(key, value));
          }
        });

        // Sort by KM ascending
        milestones.sort((a, b) {
          final kmA = a.value['km'] as int? ?? 0;
          final kmB = b.value['km'] as int? ?? 0;
          return kmA.compareTo(kmB);
        });

        // Check which milestones have been passed
        for (var milestone in milestones) {
          final kmMilestone = milestone.value['km'] as int? ?? 0;
          final action = milestone.value['action'] as String? ?? 'Periksa';

          // Jika odometer saat ini > milestone km, berarti KPB ini sudah lewat
          if (currentOdometer > kmMilestone) {
            // Estimate tanggal service - set ke beberapa hari yang lalu
            // Semakin jauh milestonenya, semakin lama tanggalnya
            // Misal: KPB 1 (1000 km) = 60 hari lalu, KPB 2 (4000) = 30 hari lalu, KPB 3 (8000) = 7 hari lalu
            final daysAgo = ((currentOdometer - kmMilestone) / 100).floor().clamp(1, 90);
            final estimatedServiceDate = now.subtract(Duration(days: daysAgo));

            // Generate unique ID dengan counter
            idCounter++;
            final id = '${now.millisecondsSinceEpoch}_$idCounter';

            final docRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('service_history')
                .doc(id);

            batch.set(docRef, {
              'motorId': motorId,
              'motorName': motorName,
              'serviceName': component,
              'serviceType': action,
              'odometer': kmMilestone,
              'date': Timestamp.fromDate(estimatedServiceDate),
            });

            batchCount++;

            // Firestore batch limit is 500 operations
            if (batchCount >= 400) {
              await batch.commit();
              // Create NEW batch after commit
              batch = _firestore.batch();
              batchCount = 0;
            }
          }
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      // Auto-generate completed successfully
    } catch (e) {
      // Error auto-generating past services, non-critical
      // User can still use the app normally
      // Error details: $e
    }
  }

  /// Clear all service history (untuk logout - optional, tidak dipanggil saat logout normal)
  Future<void> clearHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('service_history')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('service_history_${user.uid}');
    } catch (e) {
      // Error clearing history
    }
  }
}

/// Provider untuk service history
final serviceHistoryProvider = NotifierProvider<ServiceHistoryNotifier, List<ServiceHistory>>(
  () => ServiceHistoryNotifier(),
);

/// Accessor untuk get unique dates
final uniqueServiceDatesProvider = Provider<List<DateTime>>((ref) {
  ref.watch(serviceHistoryProvider);
  return ref.read(serviceHistoryProvider.notifier).getUniqueDates();
});

/// Accessor untuk get history by date
final serviceHistoryByDateProvider = Provider.family<List<ServiceHistory>, DateTime>((ref, date) {
  ref.watch(serviceHistoryProvider);
  return ref.read(serviceHistoryProvider.notifier).getHistoryByDate(date);
});

/// Accessor untuk get history by motor
final serviceHistoryByMotorProvider = Provider.family<List<ServiceHistory>, String>((ref, motorId) {
  ref.watch(serviceHistoryProvider);
  return ref.read(serviceHistoryProvider.notifier).getHistoryByMotor(motorId);
});

/// Accessor untuk get grouped services by component
final groupedServicesByComponentProvider = Provider<List<ComponentServiceGroup>>((ref) {
  ref.watch(serviceHistoryProvider);
  return ref.read(serviceHistoryProvider.notifier).getGroupedByComponent();
});

/// Accessor untuk get history by component name
final serviceHistoryByComponentProvider = Provider.family<List<ServiceHistory>, String>((ref, componentName) {
  ref.watch(serviceHistoryProvider);
  return ref.read(serviceHistoryProvider.notifier).getHistoryByComponent(componentName);
});
