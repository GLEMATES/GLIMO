import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/service_history_provider.dart';

class ComponentTimelineScreen extends ConsumerWidget {
  final String componentName;

  const ComponentTimelineScreen({
    super.key,
    required this.componentName,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String historyId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hapus Riwayat Servis?',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Yakin ingin menghapus riwayat servis "$title"?',
            style: AppTypography.bodyLarge,
          ),
          actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: AppSpacing.m),
                ElevatedButton(
                  onPressed: () async {
                    // Delete dari provider
                    await ref.read(serviceHistoryProvider.notifier).deleteHistory(historyId);

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Riwayat servis berhasil dihapus.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: AppColors.normalHover,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(AppSpacing.m),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.normalHover,
                    foregroundColor: AppColors.neutral0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch history for this component
    final componentHistory = ref.watch(serviceHistoryByComponentProvider(componentName));

    // Calculate statistics
    final totalGanti = componentHistory.where((h) => h.serviceType.contains('Ganti')).length;
    final totalPeriksa = componentHistory.where((h) => h.serviceType.contains('Periksa')).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timeline Servis',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
          ),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: IconThemeData(color: AppColors.neutral0),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.all(AppSpacing.l),
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.normalHover.withValues(alpha: 0.1),
                    AppColors.normalHover.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.normalHover.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.normalHover.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.build_circle,
                          color: AppColors.normalHover,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              componentName,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Riwayat Lengkap',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.neutral0,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$totalGanti',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.normalHover,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kali Ganti',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.neutral300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '$totalPeriksa',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kali Periksa',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.neutral300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${componentHistory.length}',
                                style: AppTypography.headlineSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Servis',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Timeline Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(
                'Timeline',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Timeline List
            if (componentHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: Center(
                  child: Text(
                    'Belum ada riwayat untuk komponen ini',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              )
            else
              ...componentHistory.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final history = entry.value;
                      final isLast = index == componentHistory.length - 1;
                      final isGanti = history.serviceType.contains('Ganti');

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.m,
                          right: AppSpacing.m,
                          bottom: AppSpacing.m,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Timeline Indicator (smaller and on the side)
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isGanti ? AppColors.normalHover : Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: AppColors.neutral300,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.s),

                              // Content Card (now much wider)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.m),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral0,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isGanti
                                          ? AppColors.normalHover.withValues(alpha: 0.3)
                                          : Colors.blue.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.neutral900.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.s,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isGanti
                                                ? AppColors.normalHover.withValues(alpha: 0.1)
                                                : Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            history.serviceType.toUpperCase(),
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isGanti ? AppColors.normalHover : Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          onPressed: () => _showDeleteConfirmationDialog(
                                            context,
                                            ref,
                                            history.id,
                                            history.serviceName,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.s),
                                    Text(
                                      _formatDate(history.date),
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.s),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppColors.neutral600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTime(history.date),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.neutral600,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.m),
                                        Icon(
                                          Icons.speed,
                                          size: 14,
                                          color: AppColors.neutral600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${history.odometer} km',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.neutral600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.s,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.neutral100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.history,
                                                size: 12,
                                                color: AppColors.neutral600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                history.getRelativeTime(),
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  color: AppColors.neutral700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
