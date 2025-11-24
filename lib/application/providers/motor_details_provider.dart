import 'package:flutter_riverpod/flutter_riverpod.dart';

class MotorDetailsState {
  final String? model;
  final String? type;
  final String? odometer;
  final DateTime? tanggalBeli;
  final DateTime? tanggalServisTerakhir;
  final int? odometerServisTerakhir;

  MotorDetailsState({
    this.model,
    this.type,
    this.odometer,
    this.tanggalBeli,
    this.tanggalServisTerakhir,
    this.odometerServisTerakhir,
  });

  MotorDetailsState copyWith({
    String? model,
    String? type,
    String? odometer,
    DateTime? tanggalBeli,
    DateTime? tanggalServisTerakhir,
    int? odometerServisTerakhir,
    bool clearTanggalServis = false, // Flag untuk clear optional fields
  }) {
    return MotorDetailsState(
      model: model ?? this.model,
      type: type ?? this.type,
      odometer: odometer ?? this.odometer,
      tanggalBeli: tanggalBeli ?? this.tanggalBeli,
      tanggalServisTerakhir: clearTanggalServis ? null : (tanggalServisTerakhir ?? this.tanggalServisTerakhir),
      odometerServisTerakhir: clearTanggalServis ? null : (odometerServisTerakhir ?? this.odometerServisTerakhir),
    );
  }
}

class MotorDetailsNotifier extends Notifier<MotorDetailsState> {
  @override
  MotorDetailsState build() {
    return MotorDetailsState();
  }

  void setModel(String model) {
    state = state.copyWith(model: model);
  }

  void setType(String type) {
    state = state.copyWith(type: type);
  }

  void setOdometer(String odometer) {
    state = state.copyWith(odometer: odometer);
  }

  void setTanggalBeli(DateTime tanggalBeli) {
    state = state.copyWith(tanggalBeli: tanggalBeli);
  }

  void setTanggalServisTerakhir(DateTime? tanggalServis, int? odometerServis) {
    state = state.copyWith(
      tanggalServisTerakhir: tanggalServis,
      odometerServisTerakhir: odometerServis,
    );
  }

  void clearTanggalServis() {
    state = state.copyWith(clearTanggalServis: true);
  }

  void clearAll() {
    state = MotorDetailsState();
  }
}

final motorDetailsProvider = NotifierProvider<MotorDetailsNotifier, MotorDetailsState>(
  MotorDetailsNotifier.new,
);