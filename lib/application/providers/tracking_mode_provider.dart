import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrackingMode {
  manual,
  automatic,
}

class TrackingModeState {
  final TrackingMode mode;
  final bool isActivityRecognitionAvailable;

  TrackingModeState({
    required this.mode,
    this.isActivityRecognitionAvailable = false,
  });

  TrackingModeState copyWith({
    TrackingMode? mode,
    bool? isActivityRecognitionAvailable,
  }) {
    return TrackingModeState(
      mode: mode ?? this.mode,
      isActivityRecognitionAvailable: isActivityRecognitionAvailable ?? this.isActivityRecognitionAvailable,
    );
  }
}

class TrackingModeNotifier extends Notifier<TrackingModeState> {
  static const String _keyTrackingMode = 'tracking_mode';

  @override
  TrackingModeState build() {
    _loadFromPreferences();
    return TrackingModeState(
      mode: TrackingMode.manual,
      isActivityRecognitionAvailable: false,
    );
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_keyTrackingMode);

      TrackingMode mode = TrackingMode.manual;

      if (modeString != null) {
        mode = modeString == 'automatic' ? TrackingMode.automatic : TrackingMode.manual;
      }

      debugPrint('⚙️ [TRACKING MODE] Loaded from preferences: $mode');

      state = state.copyWith(mode: mode);
    } catch (e) {
      debugPrint('❌ [TRACKING MODE] Error loading preferences: $e');
    }
  }

  Future<void> setMode(TrackingMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTrackingMode, mode == TrackingMode.automatic ? 'automatic' : 'manual');

      debugPrint('⚙️ [TRACKING MODE] Mode changed to: $mode');

      state = state.copyWith(mode: mode);
    } catch (e) {
      debugPrint('❌ [TRACKING MODE] Error saving mode: $e');
    }
  }

  void setActivityRecognitionAvailable(bool available) {
    debugPrint('⚙️ [TRACKING MODE] Activity Recognition available: $available');
    state = state.copyWith(isActivityRecognitionAvailable: available);
  }

  bool get isAutoMode => state.mode == TrackingMode.automatic;
  bool get isManualMode => state.mode == TrackingMode.manual;

  String get modeName {
    switch (state.mode) {
      case TrackingMode.manual:
        return 'Manual';
      case TrackingMode.automatic:
        return 'Otomatis';
    }
  }

  String get modeDescription {
    switch (state.mode) {
      case TrackingMode.manual:
        return 'Gunakan tombol untuk mulai/berhenti tracking';
      case TrackingMode.automatic:
        return 'Tracking dimulai otomatis saat berkendara';
    }
  }
}

final trackingModeProvider = NotifierProvider<TrackingModeNotifier, TrackingModeState>(() {
  return TrackingModeNotifier();
});
