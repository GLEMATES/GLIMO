import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';

/// Show component info popup with image and description
void showComponentInfoPopup({
  required BuildContext context,
  required String title,
  required String imagePath,
  required String description,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.neutral600,
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.neutral200,
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  top: AppSpacing.l,
                  bottom: AppSpacing.l + MediaQuery.of(context).padding.bottom + 80, // Extra padding for bottom nav bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.neutral100,
                                  borderRadius: BorderRadius.circular(AppSpacing.m),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: AppColors.neutral400,
                                    ),
                                    const SizedBox(height: AppSpacing.s),
                                    Text(
                                      'Gambar tidak tersedia',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.l),

                    // Description title
                    Text(
                      'Deskripsi',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s),

                    // Description text
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
