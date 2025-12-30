import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DebugEventType {
  info,
  success,
  warning,
  error,
  activityChange,
  trackingStart,
  trackingStop,
  autoStopScheduled,
  autoStopCancelled,
  autoStopTriggered,
  autoSave,
}

class DebugEvent {
  final DateTime timestamp;
  final String message;
  final DebugEventType type;
  final Map<String, dynamic>? data;

  DebugEvent({
    required this.message,
    required this.type,
    this.data,
  }) : timestamp = DateTime.now();

  String get icon {
    switch (type) {
      case DebugEventType.info:
        return 'ℹ️';
      case DebugEventType.success:
        return '✅';
      case DebugEventType.warning:
        return '⚠️';
      case DebugEventType.error:
        return '❌';
      case DebugEventType.activityChange:
        return '🎯';
      case DebugEventType.trackingStart:
        return '▶️';
      case DebugEventType.trackingStop:
        return '⏹️';
      case DebugEventType.autoStopScheduled:
        return '⏰';
      case DebugEventType.autoStopCancelled:
        return '🔄';
      case DebugEventType.autoStopTriggered:
        return '🛑';
      case DebugEventType.autoSave:
        return '💾';
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class DebugPanelState {
  final bool isEnabled;
  final bool isPanelOpen;
  final List<DebugEvent> events;
  final Map<String, dynamic> currentStatus;
  final Map<String, dynamic>? lastTripSummary;

  DebugPanelState({
    this.isEnabled = true,
    this.isPanelOpen = false,
    this.events = const [],
    this.currentStatus = const {},
    this.lastTripSummary,
  });

  DebugPanelState copyWith({
    bool? isEnabled,
    bool? isPanelOpen,
    List<DebugEvent>? events,
    Map<String, dynamic>? currentStatus,
    Map<String, dynamic>? lastTripSummary,
  }) {
    return DebugPanelState(
      isEnabled: isEnabled ?? this.isEnabled,
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      events: events ?? this.events,
      currentStatus: currentStatus ?? this.currentStatus,
      lastTripSummary: lastTripSummary ?? this.lastTripSummary,
    );
  }
}

class DebugPanelNotifier extends Notifier<DebugPanelState> {
  static const int maxEvents = 50;

  @override
  DebugPanelState build() {
    return DebugPanelState();
  }

  void toggleEnabled() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }

  void togglePanel() {
    state = state.copyWith(isPanelOpen: !state.isPanelOpen);
  }

  void openPanel() {
    state = state.copyWith(isPanelOpen: true);
  }

  void closePanel() {
    state = state.copyWith(isPanelOpen: false);
  }

  void addEvent(String message, DebugEventType type, [Map<String, dynamic>? data]) {
    if (!state.isEnabled) return;

    final event = DebugEvent(message: message, type: type, data: data);
    final events = [event, ...state.events];

    if (events.length > maxEvents) {
      events.removeRange(maxEvents, events.length);
    }

    state = state.copyWith(events: events);

    debugPrint('[DEBUG] ${event.icon} ${event.formattedTime} - $message');
  }

  void updateCurrentStatus(Map<String, dynamic> status) {
    state = state.copyWith(currentStatus: status);
  }

  void updateLastTripSummary(Map<String, dynamic> summary) {
    state = state.copyWith(lastTripSummary: summary);
  }

  void clearEvents() {
    state = state.copyWith(events: []);
  }

  void clearAll() {
    state = DebugPanelState(isEnabled: state.isEnabled);
  }
}

final debugPanelProvider = NotifierProvider<DebugPanelNotifier, DebugPanelState>(() {
  return DebugPanelNotifier();
});
