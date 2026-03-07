import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/motor_list_provider.dart';
import '../../providers/servis_schedule_provider.dart';
import '../../providers/service_history_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/service_card_new.dart';
import '../../../core/utils/logger.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  bool _isKetentuanExpanded = false;
  bool _isLoadingMotors = true;

  @override
  void initState() {
    super.initState();
    Logger.info('MonitoringScreen opened', tag: 'MONITORING');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Logger.log('Loading motors...', tag: 'MONITORING');

      // Wait for motors to load before rendering
      await ref.read(motorListProvider.notifier).loadMotors();

      if (mounted) {
        setState(() {
          _isLoadingMotors = false;
        });
      }

      ref.invalidate(servisScheduleProvider);
      _fixReferenceDateIfNeeded();
    });
  }

  Future<void> _fixReferenceDateIfNeeded() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final motors = ref.read(motorListProvider);
    final activeMotor = motors.where((m) => m.isActive).firstOrNull ?? motors.firstOrNull;
    if (activeMotor == null) return;

    final currentOdometer = int.tryParse(activeMotor.odometer) ?? 0;
    if (currentOdometer < 1000) return;

    final now = DateTime.now();
    final monthsFromRef = (now.year - activeMotor.tanggalBeli.year) * 12 +
        (now.month - activeMotor.tanggalBeli.month);

    final expectedMonths = (currentOdometer / 1000).round();

    if (monthsFromRef < expectedMonths - 3) {
      Logger.warn('Reference date seems wrong! Recalculating...', tag: 'FIX');
      Logger.log('Current: $monthsFromRef months, Expected: ~$expectedMonths months', tag: 'FIX');

      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore.collection('motors').get();

        Map<String, dynamic>? serviceSchedule;
        final motorModel = activeMotor.model.toLowerCase();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final category = (data['category'] as String?)?.toLowerCase() ?? '';
          final motorName = (data['motor_name'] as String?)?.toLowerCase() ?? '';

          if (category == motorModel ||
              motorName.contains(motorModel) ||
              motorModel.contains(motorName.split(',')[0].trim())) {
            serviceSchedule = data;
            break;
          }
        }

        if (serviceSchedule != null) {
          final newRefDate = _estimateReferenceDateFromOdometer(currentOdometer, serviceSchedule);
          final newMonths = (now.year - newRefDate.year) * 12 + (now.month - newRefDate.month);

          Logger.log('New reference date: $newRefDate', tag: 'FIX');
          Logger.log('New months from reference: $newMonths', tag: 'FIX');

          await ref.read(motorListProvider.notifier).updateTanggalBeli(activeMotor.id, newRefDate);
          ref.invalidate(servisScheduleProvider);

          Logger.success('Reference date updated!', tag: 'FIX');
        }
      } catch (e) {
        Logger.error('Failed to fix reference date', tag: 'FIX', error: e);
      }
    }
  }

  DateTime _estimateReferenceDateFromOdometer(int currentOdometer, Map<String, dynamic> serviceSchedule) {
    final services = (serviceSchedule['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (services.isEmpty) return DateTime.now();

    final List<MapEntry<int, int>> milestones = [];
    for (var service in services) {
      final schedule = service['schedule'] as Map<String, dynamic>?;
      if (schedule != null) {
        schedule.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final km = value['km'] as int?;
            final months = value['months'] as int?;
            if (km != null && months != null) {
              milestones.add(MapEntry(km, months));
            }
          }
        });
      }
    }

    milestones.sort((a, b) => a.key.compareTo(b.key));
    if (milestones.isEmpty) return DateTime.now();

    MapEntry<int, int>? previous;
    MapEntry<int, int>? next;

    for (var m in milestones) {
      if (currentOdometer >= m.key) {
        previous = m;
      } else {
        next = m;
        break;
      }
    }

    double estimatedMonths;
    if (previous == null) {
      estimatedMonths = 0;
    } else if (next == null) {
      estimatedMonths = previous.value.toDouble();
    } else {
      final kmRange = next.key - previous.key;
      final monthsRange = next.value - previous.value;
      final progress = kmRange > 0 ? (currentOdometer - previous.key) / kmRange : 0.0;
      estimatedMonths = previous.value + (progress * monthsRange);
    }

    return DateTime.now().subtract(Duration(days: (estimatedMonths * 30).round()));
  }

  void _showConfirmationDialog(
    BuildContext context,
    String serviceName,
    String serviceType,
    int currentOdometer,
    String motorId,
    String motorName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss while loading
      builder: (BuildContext dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Konfirmasi',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Sudah $serviceType $serviceName?',
                style: AppTypography.bodyLarge,
              ),
              actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      ),
                      child: const Text('Belum'),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Prevent double tap
                              setState(() {
                                isLoading = true;
                              });

                              try {
                                await ref.read(serviceHistoryProvider.notifier).addServiceHistory(
                                  motorId: motorId,
                                  motorName: motorName,
                                  serviceName: serviceName,
                                  serviceType: serviceType,
                                  odometer: currentOdometer,
                                );

                                ref.invalidate(servisScheduleProvider);

                                // ignore: use_build_context_synchronously
                                Navigator.of(dialogContext).pop();

                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$serviceName berhasil dicatat!',
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: AppColors.neutral0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Progress tracking akan berlanjut ke milestone berikutnya.',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.neutral0.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(AppSpacing.m),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.m),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                // Reset loading state on error
                                setState(() {
                                  isLoading = false;
                                });

                                // Show error
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal menyimpan: ${e.toString()}',
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
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.normalHover,
                        foregroundColor: AppColors.neutral0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.neutral0),
                              ),
                            )
                          : const Text('Sudah'),
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
    // Show loading indicator while motors are being loaded
    if (_isLoadingMotors) {
      return Scaffold(
        backgroundColor: AppColors.neutral0,
        appBar: AppBar(
          title: Text(
            'Monitoring Servis',
            style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
          ),
          backgroundColor: AppColors.normalHover,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.normalHover),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Memuat data motor...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // PENTING: Gunakan watch() agar reactive!
    // ref tersedia dari ConsumerState
    final motors = ref.watch(motorListProvider);
    final Motor? activeMotor = motors.where((m) => m.isActive).firstOrNull ?? motors.firstOrNull;

    debugPrint('🖥️ [MONITORING] Total motors: ${motors.length}');

    if (activeMotor == null) {
      debugPrint('❌ [MONITORING] No active motor found!');
    } else {
      debugPrint('🏍️ [MONITORING] Active motor: ${activeMotor.model}');
      debugPrint('🏍️ [MONITORING] Odometer: ${activeMotor.odometer} km');
      debugPrint('🏍️ [MONITORING] Reference date: ${activeMotor.tanggalBeli}');
      final now = DateTime.now();
      final monthsFromRef = (now.year - activeMotor.tanggalBeli.year) * 12 +
          (now.month - activeMotor.tanggalBeli.month);
      debugPrint('🏍️ [MONITORING] Months from reference: $monthsFromRef');
    }

    if (activeMotor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Logger.warn('No motor found, redirecting to motor-details', tag: 'MONITORING');
          context.go('/motor-details');
        }
      });

      return Scaffold(
        backgroundColor: AppColors.neutral0,
        appBar: AppBar(
          title: Text(
            'Monitoring Servis',
            style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
          ),
          backgroundColor: AppColors.normalHover,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.normalHover),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Belum ada motor, mengalihkan...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fetch servis schedule berdasarkan motor model
    final servisSchedule = ref.watch(servisScheduleProvider(activeMotor.model));

    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        title: Text(
          'Monitoring Servis',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
      ),
      body: servisSchedule.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat data servis'),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Motor model: ${activeMotor.model}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Error: $error',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
            ),
          );
        },
        data: (schedule) {
          if (schedule == null) {
            debugPrint('❌ [MONITORING] Schedule is NULL for ${activeMotor.model}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Data servis tidak ditemukan untuk motor: ${activeMotor.model}'),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Pastikan motor tersedia di Firestore',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            );
          }

          debugPrint('');
          debugPrint('📋 [MONITORING] ========================================');
          debugPrint('📋 [MONITORING] SERVICE SCHEDULE LOADED');
          debugPrint('📋 [MONITORING] Motor: ${schedule.motorName}');
          debugPrint('📋 [MONITORING] Category: ${schedule.category}');
          debugPrint('📋 [MONITORING] Total services: ${schedule.services.length}');
          debugPrint('📋 [MONITORING] ========================================');

          // Hitung odometer
          int currentOdometer = 0;
          try {
            currentOdometer = int.parse(activeMotor.odometer);
          } catch (e) {
            currentOdometer = 0;
          }

          int initialOdometer = 0;
          try {
            initialOdometer = int.parse(activeMotor.odometerAwal);
          } catch (e) {
            initialOdometer = 0;
          }

          final motorPurchaseDate = activeMotor.tanggalBeli;

          final allServices = schedule.services;

          if (allServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tidak ada data servis untuk motor ini'),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Motor: ${schedule.motorName}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.l),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.normalHover,
                              AppColors.normalHover.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.normalHover.withValues(alpha: 0.3),
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
                                  padding: const EdgeInsets.all(AppSpacing.s),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral0.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppSpacing.s),
                                  ),
                                  child: Icon(
                                    Icons.build_circle,
                                    color: AppColors.neutral0,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Jadwal Servis Berkala',
                                        style: AppTypography.titleLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.neutral0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${activeMotor.type} - ${activeMotor.model}',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.neutral0.withValues(alpha: 0.9),
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
                      const SizedBox(height: AppSpacing.m),

                      // Expandable Ketentuan & Catatan
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isKetentuanExpanded = !_isKetentuanExpanded;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(AppSpacing.m),
                            border: Border.all(
                              color: _isKetentuanExpanded
                                  ? AppColors.normalHover.withValues(alpha: 0.5)
                                  : AppColors.neutral300,
                              width: _isKetentuanExpanded ? 2 : 1,
                            ),
                            boxShadow: _isKetentuanExpanded
                                ? [
                                    BoxShadow(
                                      color: AppColors.normalHover.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            children: [
                              // Header (Always visible)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.s),
                                      decoration: BoxDecoration(
                                        color: AppColors.normalHover.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.s),
                                      ),
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        color: AppColors.normalHover,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.m),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ketentuan & Catatan Servis',
                                            style: AppTypography.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.dark,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _isKetentuanExpanded
                                                ? 'Tap untuk sembunyikan'
                                                : 'Tap untuk baca selengkapnya',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.neutral600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _isKetentuanExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: AppColors.normalHover,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),

                              // Expandable Content
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.m,
                                    0,
                                    AppSpacing.m,
                                    AppSpacing.m,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Divider(color: AppColors.neutral300),
                                      const SizedBox(height: AppSpacing.m),

                                      // Ketentuan Servis
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.m),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSpacing.s),
                                          border: Border.all(
                                            color: AppColors.info.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 18,
                                                  color: AppColors.info,
                                                ),
                                                const SizedBox(width: AppSpacing.s),
                                                Text(
                                                  'Ketentuan Servis',
                                                  style: AppTypography.bodyMedium.copyWith(
                                                    color: AppColors.info,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.s),
                                            Text(
                                              'Servis dilakukan berdasarkan KM atau Waktu, mana yang tercapai lebih dulu.',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.neutral700,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.s),
                                            Divider(color: AppColors.info.withValues(alpha: 0.3)),
                                            const SizedBox(height: AppSpacing.s),
                                            _buildLegendItem('P', 'Periksa (bersihkan, setel, lumasi, atau ganti bila perlu)'),
                                            const SizedBox(height: AppSpacing.xs),
                                            _buildLegendItem('G', 'Ganti'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.m),

                                      // Catatan Penting
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.m),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSpacing.s),
                                          border: Border.all(
                                            color: AppColors.warning.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 18,
                                                  color: AppColors.warning,
                                                ),
                                                const SizedBox(width: AppSpacing.s),
                                                Text(
                                                  'Catatan Penting',
                                                  style: AppTypography.bodyMedium.copyWith(
                                                    color: AppColors.warning,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.s),
                                            _buildNoteItem('*1', 'Pada pembacaan odometer lebih tinggi, ulangilah pada interval frekuensi yang telah ditentukan'),
                                            _buildNoteItem('*2', 'Servis lebih sering jika seringkali dikendarai di daerah yang basah atau berdebu'),
                                            _buildNoteItem('*3', 'Servislah lebih sering jika dikendarai di musim hujan atau pada kecepatan tinggi'),
                                            _buildNoteItem('*4', 'Penggantian memerlukan keterampilan mekanis'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: _isKetentuanExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 300),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Column(
                    children: allServices.map((service) {
                      final componentHistory = ref.read(serviceHistoryProvider.notifier)
                          .getHistoryByComponent(service.component);

                      DateTime? componentLastServiceDate;
                      int? componentLastServiceOdometer;

                      if (componentHistory.isNotEmpty) {
                        final mostRecent = componentHistory.first;
                        componentLastServiceDate = mostRecent.date;
                        componentLastServiceOdometer = mostRecent.odometer;
                      }

                      final nextServiceInfo = ServiceProgressCalculator.calculateNextService(
                        serviceItem: service,
                        currentOdometer: currentOdometer,
                        initialOdometer: initialOdometer,
                        motorPurchaseDate: motorPurchaseDate,
                        lastServiceDate: componentLastServiceDate,
                        lastServiceOdometer: componentLastServiceOdometer,
                      );

                      if (nextServiceInfo == null) {
                        debugPrint('⚠️ [MONITORING] ${service.component} - nextServiceInfo is NULL');
                        return const SizedBox.shrink();
                      }

                      final progressPercent = nextServiceInfo.getProgressPercentage();
                      final isDue = nextServiceInfo.isDue();

                      debugPrint('');
                      debugPrint('🔧 [MONITORING] Component: ${service.component}');
                      debugPrint('   📊 Current KM: ${nextServiceInfo.currentKm} km');
                      debugPrint('   📊 Current Months: ${nextServiceInfo.monthsSinceStart} bulan');
                      debugPrint('   ⏰ Target KM: ${nextServiceInfo.nextService.km} km');
                      debugPrint('   ⏰ Target Months: ${nextServiceInfo.nextService.months} bulan');
                      debugPrint('   📈 KM Progress: ${(nextServiceInfo.kmProgress * 100).toStringAsFixed(1)}%');
                      debugPrint('   📈 Time Progress: ${(nextServiceInfo.timeProgress * 100).toStringAsFixed(1)}%');
                      debugPrint('   📈 Overall: $progressPercent% (${nextServiceInfo.triggerType})');
                      debugPrint('   🔘 Status: ${isDue ? "WAKTUNYA SERVIS" : "Belum waktunya (abu-abu)"}');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: ServiceCardNew(
                          component: service.component,
                          note: service.note,
                          nextServiceInfo: nextServiceInfo,
                          onPressed: nextServiceInfo.isDue()
                              ? () => _showConfirmationDialog(
                                    context,
                                    service.component,
                                    nextServiceInfo.nextService.action,
                                    currentOdometer,
                                    activeMotor.id,
                                    activeMotor.model,
                                  )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String code, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral0,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String code, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral0,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              description,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
