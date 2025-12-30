import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debug_panel_provider.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

class DebugPanelWidget extends ConsumerWidget {
  const DebugPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugState = ref.watch(debugPanelProvider);

    if (!debugState.isEnabled) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomNavBarHeight = 80.0;
    final safeBottomMargin = bottomPadding + bottomNavBarHeight + 16;

    return Stack(
      children: [
        if (debugState.isPanelOpen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => ref.read(debugPanelProvider.notifier).closePanel(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        if (debugState.isPanelOpen)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            bottom: safeBottomMargin,
            child: _buildPanel(context, ref, debugState),
          ),
        Positioned(
          bottom: safeBottomMargin,
          right: 16,
          child: _buildFloatingButton(context, ref, debugState),
        ),
      ],
    );
  }

  Widget _buildFloatingButton(BuildContext context, WidgetRef ref, DebugPanelState state) {
    return FloatingActionButton(
      onPressed: () => ref.read(debugPanelProvider.notifier).togglePanel(),
      backgroundColor: AppColors.normalHover,
      child: Icon(
        state.isPanelOpen ? Icons.close : Icons.bug_report,
        color: AppColors.neutral0,
      ),
    );
  }

  Widget _buildPanel(BuildContext context, WidgetRef ref, DebugPanelState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(ref),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatus(state),
                  const SizedBox(height: AppSpacing.l),
                  _buildEventLogs(state),
                  if (state.lastTripSummary != null) ...[
                    const SizedBox(height: AppSpacing.l),
                    _buildLastTripSummary(state),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.normalHover,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: AppColors.neutral0),
          const SizedBox(width: AppSpacing.s),
          Text(
            'AUTO TRACKING DEBUG',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.neutral0),
            onPressed: () => ref.read(debugPanelProvider.notifier).clearEvents(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(DebugPanelState state) {
    final status = state.currentStatus;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: AppColors.normalHover, size: 20),
              const SizedBox(width: AppSpacing.s),
              Text(
                'CURRENT STATUS',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _buildStatusRow('Mode', status['mode'] ?? '-'),
          _buildStatusRow('Tracking', status['tracking'] ?? '-'),
          if (status['activity'] != null)
            _buildStatusRow('Activity', status['activity']),
          if (status['distance'] != null)
            _buildStatusRow('Distance', status['distance']),
          if (status['duration'] != null)
            _buildStatusRow('Duration', status['duration']),
          if (status['autoStopTimer'] != null)
            _buildStatusRow('Auto-stop', status['autoStopTimer']),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          Text(
            ': ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogs(DebugPanelState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.normalHover, size: 20),
              const SizedBox(width: AppSpacing.s),
              Text(
                'EVENT LOGS (Latest ${state.events.length})',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.neutral0,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: state.events.isEmpty
                ? Center(
                    child: Text(
                      'No events yet',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    itemCount: state.events.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = state.events[index];
                      return _buildEventItem(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(DebugEvent event) {
    Color textColor;
    switch (event.type) {
      case DebugEventType.error:
        textColor = AppColors.error;
        break;
      case DebugEventType.warning:
        textColor = Colors.orange;
        break;
      case DebugEventType.success:
        textColor = AppColors.success;
        break;
      default:
        textColor = AppColors.neutral900;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.formattedTime,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral600,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                event.icon,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: textColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (event.data != null && event.data!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 60, top: 2),
              child: Text(
                event.data.toString(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.neutral600,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastTripSummary(DebugPanelState state) {
    final summary = state.lastTripSummary!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.s),
              Text(
                'LAST AUTO-SAVE',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _buildSummaryRow('Distance', summary['distance'] ?? '-'),
          _buildSummaryRow('Duration', summary['duration'] ?? '-'),
          _buildSummaryRow('Motor', summary['motor'] ?? '-'),
          _buildSummaryRow('Odometer', summary['odometer'] ?? '-'),
          if (summary['from'] != null)
            _buildSummaryRow('From', summary['from']),
          if (summary['to'] != null)
            _buildSummaryRow('To', summary['to']),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ),
          Text(
            ': ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
