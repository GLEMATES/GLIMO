import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_typography.dart';
import '../../themes/app_spacing.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/motor_details_provider.dart';

class MotorModelScreen extends ConsumerWidget {
  const MotorModelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Model Motor',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: ListView(
          children: [
            _MotorModelItem(
              key: const ValueKey('scooter'),
              title: 'Scooter',
              subtitle: 'Motor Matic',
              info: 'Motor dengan transmisi otomatis, tidak perlu oper gigi.',
              onTap: () {
                ref.read(motorDetailsProvider.notifier).setModel('Scooter');
                context.pop();
              },
            ),
            _MotorModelItem(
              key: const ValueKey('cub'),
              title: 'Cub',
              subtitle: 'Motor Gigi',
              info: 'Motor dengan transmisi manual, membutuhkan oper gigi.',
              onTap: () {
                ref.read(motorDetailsProvider.notifier).setModel('Cub');
                context.pop();
              },
            ),
            _MotorModelItem(
              key: const ValueKey('sport'),
              title: 'Sport',
              subtitle: 'Kopling Manual',
              info: 'Motor dengan kopling manual, memberikan kontrol lebih baik.',
              onTap: () {
                ref.read(motorDetailsProvider.notifier).setModel('Sport');
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MotorModelItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String info;
  final VoidCallback? onTap;

  const _MotorModelItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.info,
    this.onTap,
  });

  void _showInfoDialog(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: screenHeight * 0.3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.m, thickness: 1),
                Text(
                  info,
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showInfoDialog(context),
              icon: Icon(
                Icons.info_outline,
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}