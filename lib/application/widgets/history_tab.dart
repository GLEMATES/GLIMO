import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/trip_history_provider.dart';
import '../providers/motor_list_provider.dart';
import '../providers/premium_limits_provider.dart';
import '../providers/subscription_status_provider.dart';
import '../screens/home/trip_detail_screen.dart';
import 'history_item_card.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  String _selectedPeriod = 'all'; // all, 7days, 30days, 90days

  List<TripHistory> _getFilteredTrips(List<TripHistory> allTrips) {
    if (_selectedPeriod == 'all') {
      return allTrips;
    }

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        return allTrips;
    }

    return allTrips.where((trip) => trip.date.isAfter(startDate)).toList();
  }

  void _showDeleteConfirmationDialog(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Hapus Riwayat Perjalanan?',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Yakin ingin menghapus riwayat perjalanan ini?',
            style: AppTypography.bodyLarge,
          ),
          actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                    try {
                      // Close dialog first
                      Navigator.of(dialogContext).pop();

                      // Show loading indicator
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutral0),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Menghapus...',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.neutral0,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.neutral700,
                            duration: const Duration(seconds: 30),
                          ),
                        );
                      }

                      // Delete trip
                      await ref.read(tripHistoryProvider.notifier).deleteTrip(tripId);

                      // Hide loading and show success
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Riwayat perjalanan berhasil dihapus.',
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
                      }
                    } catch (e) {
                      // Hide loading and show error
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal menghapus: ${e.toString()}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(AppSpacing.m),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.m),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
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

  void _showOdometerDialog(BuildContext context) {
    // Get active motor and auto-fill start odometer
    final activeMotor = ref.read(motorListProvider.notifier).getActiveMotor();
    if (activeMotor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Motor tidak ditemukan',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.m),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Auto-fill start odometer from current motor odometer
    final startController = TextEditingController(text: activeMotor.odometer);
    final endController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Auto-calculate distance
            int? distance;
            if (startController.text.isNotEmpty && endController.text.isNotEmpty) {
              final start = int.tryParse(startController.text);
              final end = int.tryParse(endController.text);
              if (start != null && end != null) {
                distance = end - start;
              }
            }

            return AlertDialog(
              title: Text(
                'Tambah Perjalanan Manual',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Odometer awal otomatis diambil dari Total Jarak Tempuh motor Anda saat ini',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: startController,
                      keyboardType: TextInputType.number,
                      enabled: false,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Odometer Awal (km) - Otomatis',
                        hintText: 'Otomatis dari Total Jarak Tempuh',
                        prefixIcon: Icon(Icons.speed, color: AppColors.neutral400),
                        filled: true,
                        fillColor: AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                          borderSide: BorderSide(color: AppColors.neutral300),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: endController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Odometer Akhir (km)',
                        hintText: 'Masukkan odometer akhir dari motor Anda',
                        helperText: 'Cek odometer di motor, misal: ${int.parse(activeMotor.odometer) + 50}',
                        prefixIcon: Icon(Icons.flag, color: AppColors.normalHover),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: distance > 0
                              ? AppColors.normalHover.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                          border: Border.all(
                            color: distance > 0
                                ? AppColors.normalHover.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              distance > 0 ? Icons.check_circle : Icons.error,
                              color: distance > 0 ? AppColors.normalHover : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Text(
                                distance > 0
                                    ? 'Jarak: $distance km'
                                    : 'Odometer akhir harus lebih besar',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: distance > 0 ? AppColors.normalHover : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
                        setState(() => errorMessage = null);

                        final start = int.tryParse(startController.text);
                        final end = int.tryParse(endController.text);

                        if (start == null || end == null) {
                          setState(() => errorMessage = 'Mohon isi odometer akhir dengan angka yang valid');
                          return;
                        }

                        if (end <= start) {
                          setState(() => errorMessage = 'Odometer akhir harus lebih besar dari odometer awal (${activeMotor.odometer} km)');
                          return;
                        }

                        try {
                          await ref.read(tripHistoryProvider.notifier).addManualTrip(
                                motorId: activeMotor.id,
                                motorName: activeMotor.model,
                                startOdometer: start,
                                endOdometer: end,
                              );

                          // ignore: use_build_context_synchronously
                          Navigator.of(dialogContext).pop();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Riwayat perjalanan berhasil ditambahkan.',
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
                        } catch (e) {
                          setState(() => errorMessage = 'Gagal menambahkan perjalanan: ${e.toString()}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.normalHover,
                        foregroundColor: AppColors.neutral0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = ref.watch(filteredTripHistoryProvider);
    final trips = _getFilteredTrips(allTrips);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final totalTrips = ref.watch(tripHistoryProvider).length;
    final hasHiddenTrips = !subscriptionStatus.isActive && totalTrips > allTrips.length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          color: AppColors.neutral0,
          child: Row(
            children: [
              // Dropdown Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.neutral600,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPeriod = newValue;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Semua Riwayat'),
                        ),
                        DropdownMenuItem(
                          value: '7days',
                          child: Text('7 Hari Terakhir'),
                        ),
                        DropdownMenuItem(
                          value: '30days',
                          child: Text('30 Hari Terakhir'),
                        ),
                        DropdownMenuItem(
                          value: '90days',
                          child: Text('90 Hari Terakhir'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              // Tambah Riwayat Button
              ElevatedButton(
                onPressed: () {
                  _showOdometerDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.normalHover,
                  foregroundColor: AppColors.neutral0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Tambah Riwayat',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasHiddenTrips)
          Container(
            margin: const EdgeInsets.all(AppSpacing.m),
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE40000), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_clock,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Terbatas',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kamu hanya bisa lihat riwayat 7 hari terakhir. Upgrade ke Premium untuk akses unlimited!',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  onPressed: () => context.push('/premium'),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.m),
        if (trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon instead of image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    size: 60,
                    color: AppColors.neutral400,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  _selectedPeriod == 'all'
                      ? 'Belum ada riwayat perjalanan'
                      : 'Tidak ada riwayat di periode ini',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    _selectedPeriod == 'all'
                        ? 'Tambahkan perjalanan manual atau gunakan GPS tracking'
                        : 'Coba pilih periode waktu yang berbeda',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Terbaru',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              ...trips.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final trip = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: HistoryItemCard(
                    number: index,
                    distance: trip.getFormattedDistance(),
                    startKm: trip.startOdometer.toString(),
                    endKm: trip.endOdometer.toString(),
                    date: trip.getRelativeTime(),
                    source: trip.source,
                    startLocation: trip.startLocation,
                    endLocation: trip.endLocation,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripDetailScreen(trip: trip),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteConfirmationDialog(context, trip.id),
                  ),
                );
              }),
            ],
          ),
        const SizedBox(height: 100),
      ],
    );
  }
}