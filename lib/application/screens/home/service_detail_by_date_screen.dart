import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/service_history_provider.dart';
import '../../widgets/service_history_card.dart';

class ServiceDetailByDateScreen extends ConsumerWidget {
  final DateTime date;

  const ServiceDetailByDateScreen({
    super.key,
    required this.date,
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
    // Fetch history for selected date
    final historyForDate = ref.watch(serviceHistoryByDateProvider(date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Servis',
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.normalHover.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppColors.normalHover,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Servis Anda',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'pada ${_formatDate(date)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                        Text(
                          'Total: ${historyForDate.length} servis',
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
            if (historyForDate.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: Center(
                  child: Text(
                    'Tidak ada riwayat untuk tanggal ini',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              )
            else
              ...historyForDate.asMap().entries.map(
                    (entry) {
                      final index = entry.key + 1;
                      final history = entry.value;
                      final formattedDate =
                          '${history.date.hour}:${history.date.minute.toString().padLeft(2, '0')}';

                      return ServiceHistoryCard(
                        number: index,
                        title: '${history.serviceType} ${history.serviceName}',
                        distance: '${history.odometer} Km',
                        date: formattedDate,
                        onDelete: () => _showDeleteConfirmationDialog(
                          context,
                          ref,
                          history.id,
                          history.serviceName,
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