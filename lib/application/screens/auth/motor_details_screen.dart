import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/motor_details_provider.dart';
import '../../providers/motor_list_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../widgets/action_button.dart';
import '../../../core/utils/logger.dart';

class MotorDetailsScreen extends ConsumerStatefulWidget {
  const MotorDetailsScreen({super.key});

  @override
  ConsumerState<MotorDetailsScreen> createState() => _MotorDetailsScreenState();
}

class _MotorDetailsScreenState extends ConsumerState<MotorDetailsScreen> {
  String? editMotorId;
  String? from;
  bool _isSaving = false;

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
                    onPressed: _isSaving ? null : () async {
                      if (_isSaving) return;

                      setState(() {
                        _isSaving = true;
                      });

                      final savedModel = motorDetails.model!;
                      final savedType = motorDetails.type!;
                      final savedOdometer = motorDetails.odometer!;
                      final savedFrom = from;
                      final savedEditMotorId = editMotorId;

                      if (!mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                        return;
                      }

                      Navigator.of(context).pop();

                      // Show loading dialog
                      if (!context.mounted) return;

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

                      try {
                        final estimatedPurchaseDate = DateTime.now();

                        if (savedFrom == 'motor-saya') {
                          if (savedEditMotorId != null) {
                            await ref.read(motorListProvider.notifier).updateMotor(
                                  savedEditMotorId,
                                  savedModel,
                                  savedType,
                                  savedOdometer,
                                ).timeout(
                                  const Duration(seconds: 10),
                                  onTimeout: () {
                                    throw Exception('Timeout saat menyimpan motor');
                                  },
                                );
                          } else {
                            await ref.read(motorListProvider.notifier).addMotor(
                                  savedModel,
                                  savedType,
                                  savedOdometer,
                                  estimatedPurchaseDate,
                                ).timeout(
                                  const Duration(seconds: 10),
                                  onTimeout: () {
                                    throw Exception('Timeout saat menyimpan motor');
                                  },
                                );
                          }

                          // Close loading dialog
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();

                          // Wait a bit for dialog to fully close
                          await Future.delayed(const Duration(milliseconds: 100));

                          // Clear form and go back
                          if (!mounted) return;
                          ref.read(motorDetailsProvider.notifier).clearAll();

                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }

                          if (context.mounted) {
                            context.pop();
                          }
                        } else {
                          Logger.log('Starting motor registration...', tag: 'MOTOR');

                          final navigator = Navigator.of(context, rootNavigator: true);
                          final router = GoRouter.of(context);

                          await ref.read(motorListProvider.notifier).addMotor(
                                savedModel,
                                savedType,
                                savedOdometer,
                                estimatedPurchaseDate,
                              ).timeout(
                                const Duration(seconds: 10),
                                onTimeout: () {
                                  throw Exception('Timeout saat menyimpan motor');
                                },
                              );

                          Logger.log('Motor saved, closing loading dialog...', tag: 'MOTOR');

                          if (!mounted) return;

                          try {
                            navigator.pop();
                            Logger.log('Loading dialog closed', tag: 'MOTOR');
                          } catch (e) {
                            Logger.error('Failed to close dialog', tag: 'MOTOR', error: e);
                          }

                          await Future.delayed(const Duration(milliseconds: 300));

                          if (!mounted) return;

                          Logger.log('Clearing form...', tag: 'MOTOR');
                          ref.read(motorDetailsProvider.notifier).clearAll();

                          setState(() {
                            _isSaving = false;
                          });

                          Logger.log('Navigating to /beranda...', tag: 'MOTOR');
                          router.go('/beranda');
                          Logger.success('Navigation to /beranda completed', tag: 'MOTOR');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }

                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal menyimpan motor ke server. Pastikan koneksi internet aktif dan coba lagi.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'TUTUP',
                              textColor: AppColors.neutral0,
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    buildForm(context, ref),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: ActionButton(
                text: 'Lanjutkan',
                onPressed: isFormValid ? showConfirmationDialog : null,
                isPrimary: true,
              ),
            ),
          ],
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
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