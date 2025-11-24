import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_profile_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class EditProfilScreen extends ConsumerStatefulWidget {
  const EditProfilScreen({super.key});

  @override
  ConsumerState<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends ConsumerState<EditProfilScreen> {
  late TextEditingController _nameController;
  String? _tempPhotoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      _nameController.text = profile.name;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _tempPhotoPath = image.path;
      });
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _tempPhotoPath = null;
    });
    await ref.read(userProfileProvider.notifier).removePhoto();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nama tidak boleh kosong',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral0, fontWeight: FontWeight.w600),
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

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProfileProvider.notifier).updateName(_nameController.text.trim());

      if (_tempPhotoPath != null) {
        await ref.read(userProfileProvider.notifier).updatePhoto(_tempPhotoPath!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil berhasil diperbarui',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral0, fontWeight: FontWeight.w600),
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
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui profil',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral0, fontWeight: FontWeight.w600),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      backgroundColor: AppColors.normalHover,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.neutral0,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                top: AppSpacing.l,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _buildPhotoSection(profile),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildNameField(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildEmailField(profile),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSaveButton(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(UserProfile profile) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neutral300,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _tempPhotoPath != null
                    ? Image.file(
                        File(_tempPhotoPath!),
                        fit: BoxFit.cover,
                      )
                    : profile.photoUrl != null
                        ? Image.file(
                            File(profile.photoUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: AppColors.neutral600,
                                size: 60,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            color: AppColors.neutral600,
                            size: 60,
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.normalHover,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neutral0,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.neutral0,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_tempPhotoPath != null || profile.photoUrl != null) ...[
          const SizedBox(height: AppSpacing.m),
          TextButton(
            onPressed: _removePhoto,
            child: Text(
              'Hapus Foto',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.normal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Lengkap',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _nameController,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral900,
          ),
          decoration: InputDecoration(
            hintText: 'Masukkan nama lengkap',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.neutral400),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.darkHover, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          enabled: false,
          controller: TextEditingController(text: profile.email),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral600,
          ),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.neutral400),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.neutral400),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.neutral400),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Email tidak dapat diubah',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.neutral600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.normalHover,
          foregroundColor: AppColors.neutral0,
          disabledBackgroundColor: AppColors.neutral300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.xxl),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.neutral0,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Simpan Perubahan',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.neutral0,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}