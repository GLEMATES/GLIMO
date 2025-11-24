import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/motor_details_provider.dart';
import '../../providers/motor_list_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_history_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';

class MotorDetailsScreen extends ConsumerStatefulWidget {
  const MotorDetailsScreen({super.key});

  @override
  ConsumerState<MotorDetailsScreen> createState() => _MotorDetailsScreenState();
}

class _MotorDetailsScreenState extends ConsumerState<MotorDetailsScreen> {
  String? editMotorId;
  String? from;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    from = uri.queryParameters['from'];
    editMotorId = uri.queryParameters['motorId'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editMotorId != null) {
        final motors = ref.read(motorListProvider);
        final motor = motors.firstWhere((m) => m.id == editMotorId);
        ref.read(motorDetailsProvider.notifier).setModel(motor.model);
        ref.read(motorDetailsProvider.notifier).setType(motor.type);
        ref.read(motorDetailsProvider.notifier).setOdometer(motor.odometer);
      }
    });
  }

  DateTime _estimatePurchaseDateFromOdometer(
    int currentOdometer,
    Map<String, dynamic> serviceSchedule,
  ) {
    final services = (serviceSchedule['services'] as List?)?.map((service) {
      return service as Map<String, dynamic>;
    }).toList() ?? [];

    if (services.isEmpty) {
      return DateTime.now();
    }

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

    if (milestones.isEmpty) {
      return DateTime.now();
    }

    MapEntry<int, int>? previousMilestone;
    MapEntry<int, int>? nextMilestone;

    for (var milestone in milestones) {
      if (currentOdometer >= milestone.key) {
        previousMilestone = milestone;
      } else {
        nextMilestone = milestone;
        break;
      }
    }

    double estimatedMonths;

    if (previousMilestone == null) {
      estimatedMonths = 0;
    } else if (nextMilestone == null) {
      estimatedMonths = previousMilestone.value.toDouble();
    } else {
      final kmRange = nextMilestone.key - previousMilestone.key;
      final monthsRange = nextMilestone.value - previousMilestone.value;
      final kmProgress = currentOdometer - previousMilestone.key;

      final progressRatio = kmRange > 0 ? kmProgress / kmRange : 0.0;

      estimatedMonths = previousMilestone.value + (progressRatio * monthsRange);
    }

    final estimatedDays = (estimatedMonths * 30).round();

    return DateTime.now().subtract(Duration(days: estimatedDays));
  }

  void _autoGeneratePastServicesInBackground(
    String model,
    String type,
    String odometer,
  ) {
    Future.microtask(() async {
      try {
        final currentOdometer = int.tryParse(odometer) ?? 0;

        if (currentOdometer < 1000) {
          return;
        }

        final firestore = FirebaseFirestore.instance;
        final motorModel = model.toLowerCase();

        if (motorModel.isEmpty) {
          return;
        }

        final snapshot = await firestore.collection('motors').get().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Timeout fetching service schedule');
          },
        );

        Map<String, dynamic>? serviceSchedule;

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

        if (serviceSchedule == null) {
          return;
        }

        final motors = ref.read(motorListProvider);
        final newMotor = motors.firstWhere(
          (m) => m.model == model && m.type == type,
        );

        final estimatedPurchaseDate = _estimatePurchaseDateFromOdometer(
          currentOdometer,
          serviceSchedule,
        );

        await ref.read(serviceHistoryProvider.notifier).autoGeneratePastServices(
              motorId: newMotor.id,
              motorName: '${newMotor.model} - ${newMotor.type}',
              currentOdometer: currentOdometer,
              motorPurchaseDate: estimatedPurchaseDate,
              serviceSchedule: serviceSchedule,
            ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Timeout auto-generating service history');
          },
        );
      } on TimeoutException catch (_) {
      } catch (_) {
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final motorDetails = ref.watch(motorDetailsProvider);

    final isFormValid = motorDetails.model != null &&
        motorDetails.type != null &&
        motorDetails.odometer != null;

    void showConfirmationDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              editMotorId != null ? 'Konfirmasi Perubahan' : 'Konfirmasi Data Motor',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataRow('Model', motorDetails.model ?? '-'),
                _buildDataRow('Jenis', motorDetails.type ?? '-'),
                _buildDataRow('Odometer', '${motorDetails.odometer ?? '-'} km'),
              ],
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
                      final savedModel = motorDetails.model!;
                      final savedType = motorDetails.type!;
                      final savedOdometer = motorDetails.odometer!;
                      final savedFrom = from;
                      final savedEditMotorId = editMotorId;

                      Navigator.of(context).pop();

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext loadingContext) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: AppColors.normalHover),
                                  const SizedBox(height: AppSpacing.l),
                                  Text(
                                    'Menyimpan data motor...',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      try {
                        final firestore = FirebaseFirestore.instance;
                        final motorModel = savedModel.toLowerCase();
                        final snapshot = await firestore.collection('motors').get();

                        Map<String, dynamic>? serviceSchedule;
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

                        final estimatedPurchaseDate = serviceSchedule != null
                            ? _estimatePurchaseDateFromOdometer(
                                int.tryParse(savedOdometer) ?? 0,
                                serviceSchedule,
                              )
                            : DateTime.now();

                        if (savedFrom == 'motor-saya') {
                          if (savedEditMotorId != null) {
                            await ref.read(motorListProvider.notifier).updateMotor(
                                  savedEditMotorId,
                                  savedModel,
                                  savedType,
                                  savedOdometer,
                                );
                          } else {
                            await ref.read(motorListProvider.notifier).addMotor(
                                  savedModel,
                                  savedType,
                                  savedOdometer,
                                  estimatedPurchaseDate,
                                );

                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }

                            _autoGeneratePastServicesInBackground(
                              savedModel,
                              savedType,
                              savedOdometer,
                            );

                            if (context.mounted) {
                              ref.read(motorDetailsProvider.notifier).clearAll();
                              context.pop();
                            }
                            return;
                          }

                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }

                          if (context.mounted) {
                            ref.read(motorDetailsProvider.notifier).clearAll();
                            context.pop();
                          }
                        } else {
                          await ref.read(motorListProvider.notifier).addMotor(
                                savedModel,
                                savedType,
                                savedOdometer,
                                estimatedPurchaseDate,
                              );

                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }

                          _autoGeneratePastServicesInBackground(
                            savedModel,
                            savedType,
                            savedOdometer,
                          );

                          await ref.read(authStateProvider.notifier).logout();

                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan data: $e'),
                              backgroundColor: AppColors.error,
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
                    child: const Text('Yakin'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editMotorId != null ? 'Detail Motor' : 'Tambah Motor',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              buildForm(context, ref),
              const Spacer(),
              ActionButton(
                text: 'Lanjutkan',
                onPressed: isFormValid ? showConfirmationDialog : null,
                isPrimary: true,
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget buildForm(BuildContext context, WidgetRef ref) {
    final motorDetails = ref.watch(motorDetailsProvider);
    return Column(
      children: [
        buildCustomInputField(
          context: context,
          label: 'Model Motor',
          value: motorDetails.model,
          onTap: () {
            context.push('/motor-model');
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        buildCustomInputField(
          context: context,
          label: 'Jenis Motor',
          value: motorDetails.type,
          onTap: motorDetails.model != null
              ? () {
                  context.push('/motor-type/${motorDetails.model}');
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xxl),
        buildCustomInputField(
          context: context,
          label: 'Odometer Terakhir',
          value: motorDetails.odometer != null ? '${motorDetails.odometer} km' : null,
          onTap: () {
            showOdometerDialog(context, ref);
          },
        ),
      ],
    );
  }

  Widget buildCustomInputField({
    required BuildContext context,
    required String label,
    String? value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: editMotorId == null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.m,
          horizontal: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.neutral400,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? label,
              style: AppTypography.bodyLarge.copyWith(
                color: value != null ? AppColors.dark : AppColors.neutral700,
              ),
            ),
            if (editMotorId == null)
              Icon(
                Icons.chevron_right,
                color: AppColors.neutral500,
              ),
          ],
        ),
      ),
    );
  }

  void showOdometerDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    final motorDetails = ref.read(motorDetailsProvider);
    if (motorDetails.odometer != null) {
      controller.text = motorDetails.odometer!;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Masukkan Odometer',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Misal: 11722',
              helperText: 'Masukkan odometer yang tertera di motor Anda',
            ),
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
                  onPressed: () {
                    ref.read(motorDetailsProvider.notifier).setOdometer(controller.text);
                    Navigator.of(context).pop();
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
  }
}