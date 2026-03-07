import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Motor {
  final String id;
  final String model;
  final String type;
  final String odometer;
  final String odometerAwal; // Odometer saat pertama kali ditambahkan
  final DateTime tanggalDitambah; // Tanggal motor ditambahkan ke app
  final DateTime tanggalBeli; // Tanggal motor dibeli (untuk tracking waktu)
  final DateTime? tanggalServisTerakhir; // Optional: Tanggal servis terakhir
  final int? odometerServisTerakhir; // Optional: Odometer saat servis terakhir
  final bool isActive;

  Motor({
    required this.id,
    required this.model,
    required this.type,
    required this.odometer,
    required this.odometerAwal,
    required this.tanggalDitambah,
    required this.tanggalBeli,
    this.tanggalServisTerakhir,
    this.odometerServisTerakhir,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'type': type,
      'odometer': odometer,
      'odometerAwal': odometerAwal,
      'tanggalDitambah': tanggalDitambah.toIso8601String(),
      'tanggalBeli': tanggalBeli.toIso8601String(),
      'tanggalServisTerakhir': tanggalServisTerakhir?.toIso8601String(),
      'odometerServisTerakhir': odometerServisTerakhir,
      'isActive': isActive,
    };
  }

  factory Motor.fromJson(Map<String, dynamic> json) {
    return Motor(
      id: json['id'],
      model: json['model'],
      type: json['type'],
      odometer: json['odometer'],
      odometerAwal: json['odometerAwal'] ?? json['odometer_awal'] ?? '0',
      tanggalDitambah: json['tanggalDitambah'] != null
          ? DateTime.parse(json['tanggalDitambah'])
          : (json['tanggal_ditambah'] != null ? DateTime.parse(json['tanggal_ditambah']) : DateTime.now()),
      tanggalBeli: json['tanggalBeli'] != null
          ? DateTime.parse(json['tanggalBeli'])
          : (json['tanggal_beli'] != null
              ? DateTime.parse(json['tanggal_beli'])
              : (json['tanggalDitambah'] != null
                  ? DateTime.parse(json['tanggalDitambah'])
                  : DateTime.now())), // Fallback untuk data lama
      tanggalServisTerakhir: json['tanggalServisTerakhir'] != null
          ? DateTime.parse(json['tanggalServisTerakhir'])
          : (json['tanggal_servis_terakhir'] != null
              ? DateTime.parse(json['tanggal_servis_terakhir'])
              : null),
      odometerServisTerakhir: json['odometerServisTerakhir'] ?? json['odometer_servis_terakhir'],
      isActive: json['isActive'] ?? false,
    );
  }
}

class MotorListNotifier extends Notifier<List<Motor>> {
  @override
  List<Motor> build() {
    loadMotors();
    return [];
  }

  Future<void> loadMotors() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = [];
        return;
      }

      // Load dari Firestore: users/{userId}/motors
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('motors')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final motors = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Motor(
            id: doc.id,
            model: data['model'] ?? 'Unknown',
            type: data['type'] ?? 'Unknown',
            odometer: data['odometer'] ?? '0',
            odometerAwal: data['odometerAwal'] ?? '0',
            tanggalDitambah: data['tanggalDitambah'] != null
                ? (data['tanggalDitambah'] as Timestamp).toDate()
                : DateTime.now(),
            tanggalBeli: data['tanggalBeli'] != null
                ? (data['tanggalBeli'] as Timestamp).toDate()
                : (data['tanggalDitambah'] != null
                    ? (data['tanggalDitambah'] as Timestamp).toDate()
                    : DateTime.now()), // Fallback untuk data lama
            tanggalServisTerakhir: data['tanggalServisTerakhir'] != null
                ? (data['tanggalServisTerakhir'] as Timestamp).toDate()
                : null,
            odometerServisTerakhir: data['odometerServisTerakhir'],
            isActive: data['isActive'] ?? false,
          );
        }).toList();

        state = motors;

        if (state.isNotEmpty && !state.any((motor) => motor.isActive)) {
          await setActiveMotor(state.first.id);
        }

        // Simpan ke SharedPreferences sebagai cache (dengan userId)
        await _saveToPreferences();
        return;
      }
    } catch (e) {
      // Error loading motors from Firebase
    }

    // Fallback ke SharedPreferences jika Firebase gagal
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final motorsJson = prefs.getString('motors_list_${user.uid}');

      if (motorsJson != null) {
        final List<dynamic> decoded = jsonDecode(motorsJson);
        state = decoded.map((json) => Motor.fromJson(json)).toList();

        if (state.isNotEmpty && !state.any((motor) => motor.isActive)) {
          await setActiveMotor(state.first.id);
        }
      }
    }
  }

  Future<void> addMotor(
    String model,
    String type,
    String odometer,
    DateTime referenceDate, {
    DateTime? tanggalServisTerakhir,
    int? odometerServisTerakhir,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isFirstMotor = state.isEmpty;
    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;

    final motorDoc = firestore
        .collection('users')
        .doc(user.uid)
        .collection('motors')
        .doc();

    final newMotor = Motor(
      id: motorDoc.id,
      model: model,
      type: type,
      odometer: odometer,
      odometerAwal: odometer,
      tanggalDitambah: now,
      tanggalBeli: referenceDate,
      tanggalServisTerakhir: tanggalServisTerakhir,
      odometerServisTerakhir: odometerServisTerakhir,
      isActive: isFirstMotor,
    );

    state = [...state, newMotor];
    await _saveToPreferences();

    try {
      debugPrint('🔄 Saving motor to Firestore: ${motorDoc.id}');
      await motorDoc.set({
        'model': model,
        'type': type,
        'odometer': odometer,
        'odometerAwal': odometer,
        'tanggalDitambah': Timestamp.fromDate(now),
        'tanggalBeli': Timestamp.fromDate(referenceDate),
        'tanggalServisTerakhir': tanggalServisTerakhir != null ? Timestamp.fromDate(tanggalServisTerakhir) : null,
        'odometerServisTerakhir': odometerServisTerakhir,
        'isActive': isFirstMotor,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout saving motor to Firestore');
        },
      );
      debugPrint('✅ Motor saved to Firestore successfully!');
    } catch (e) {
      debugPrint('❌ Failed to save motor to Firestore: $e');
      state = state.where((motor) => motor.id != motorDoc.id).toList();
      await _saveToPreferences();
      rethrow;
    }
  }

  Future<void> updateMotor(String id, String model, String type, String odometer) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    // Update di Firestore
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('motors')
        .doc(id)
        .update({
      'model': model,
      'type': type,
      'odometer': odometer,
    });

    state = state.map((motor) {
      if (motor.id == id) {
        return Motor(
          id: id,
          model: model,
          type: type,
          odometer: odometer,
          odometerAwal: motor.odometerAwal,
          tanggalDitambah: motor.tanggalDitambah,
          tanggalBeli: motor.tanggalBeli, // Keep existing tanggalBeli
          tanggalServisTerakhir: motor.tanggalServisTerakhir, // Keep existing
          odometerServisTerakhir: motor.odometerServisTerakhir, // Keep existing
          isActive: motor.isActive,
        );
      }
      return motor;
    }).toList();

    await _saveToPreferences();
  }

  Future<void> deleteMotor(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final motorToDelete = state.firstWhere((motor) => motor.id == id);

    // Delete dari Firestore
    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('motors')
        .doc(id)
        .delete();

    state = state.where((motor) => motor.id != id).toList();

    if (motorToDelete.isActive && state.isNotEmpty) {
      await setActiveMotor(state.first.id);
    } else {
      await _saveToPreferences();
    }
  }

  Future<void> setActiveMotor(String motorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Update semua motor di Firestore
    for (var motor in state) {
      final motorRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('motors')
          .doc(motor.id);
      batch.update(motorRef, {'isActive': motor.id == motorId});
    }

    await batch.commit();

    state = state.map((motor) {
      return Motor(
        id: motor.id,
        model: motor.model,
        type: motor.type,
        odometer: motor.odometer,
        odometerAwal: motor.odometerAwal,
        tanggalDitambah: motor.tanggalDitambah,
        tanggalBeli: motor.tanggalBeli,
        tanggalServisTerakhir: motor.tanggalServisTerakhir,
        odometerServisTerakhir: motor.odometerServisTerakhir,
        isActive: motor.id == motorId,
      );
    }).toList();

    await _saveToPreferences();
  }

  Motor? getActiveMotor() {
    try {
      return state.firstWhere((motor) => motor.isActive);
    } catch (e) {
      return state.isNotEmpty ? state.first : null;
    }
  }

  Future<void> updateTanggalBeli(String motorId, DateTime newTanggalBeli) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('motors')
        .doc(motorId)
        .update({
      'tanggalBeli': Timestamp.fromDate(newTanggalBeli),
    });

    state = state.map((motor) {
      if (motor.id == motorId) {
        return Motor(
          id: motor.id,
          model: motor.model,
          type: motor.type,
          odometer: motor.odometer,
          odometerAwal: motor.odometerAwal,
          tanggalDitambah: motor.tanggalDitambah,
          tanggalBeli: newTanggalBeli,
          tanggalServisTerakhir: motor.tanggalServisTerakhir,
          odometerServisTerakhir: motor.odometerServisTerakhir,
          isActive: motor.isActive,
        );
      }
      return motor;
    }).toList();

    await _saveToPreferences();
  }

  Future<void> _saveToPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final motorsJson = jsonEncode(state.map((motor) => motor.toJson()).toList());
    await prefs.setString('motors_list_${user.uid}', motorsJson);
  }

  Future<void> clearMotors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('motors_list_${user.uid}');
    }
    state = [];
  }
}

final motorListProvider = NotifierProvider<MotorListNotifier, List<Motor>>(
  () => MotorListNotifier(),
);
