import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class TentangAplikasiScreen extends ConsumerWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tentang Aplikasi',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      backgroundColor: AppColors.normalHover,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang di Glemo!',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Deskripsi',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Glemo adalah aplikasi yang membantu pemilik motor dalam memantau kondisi kendaraan, mengingatkan jadwal servis, serta menyimpan riwayat perawatan dengan lebih mudah, teratur, dan efisien.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral700,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Fitur',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Glemo hadir untuk mendukung kenyamanan berkendara melalui fitur-fitur seperti:',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral700,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: AppSpacing.m),
              _buildBulletPoint(
                'Monitoring Jarak Tempuh: Perhitungan jarak tempuh otomatis menggunakan GPS untuk memantau seberapa jauh motor sudah digunakan.',
              ),
              _buildBulletPoint(
                'Monitoring Jadwal Servis: Pantau jadwal servis yang menampilkan progress bar sebagai indikator visual untuk memantau waktu atau jarak tempuh menuju servis berikutnya.',
              ),
              _buildBulletPoint(
                'Riwayat Servis: Simpan catatan servis agar lebih mudah melacak perawatan sebelumnya.',
              ),
              _buildBulletPoint(
                'Pengingat Servis: Notifikasi otomatis untuk jadwal servis berkala seperti oli, rem, dan filter udara.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tujuan Aplikasi',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Glemo bertujuan untuk membantu pemilik motor menjaga performa kendaraannya tetap prima dengan memanfaatkan teknologi digital yang praktis dan modern.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.neutral700,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Keunggulan',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _buildBulletPoint(
                'Pemantauan real-time berbasis GPS untuk akurasi data jarak tempuh.',
              ),
              _buildBulletPoint(
                'Pengingat servis otomatis agar tidak melewatkan perawatan penting.',
              ),
              _buildBulletPoint(
                'Riwayat servis terorganisir dengan akses cepat dan jelas.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Kontak dan Dukungan',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.normal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.neutral700,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Jika Anda memiliki pertanyaan atau membutuhkan bantuan, hubungi kami di Email: ',
                    ),
                    TextSpan(
                      text: 'hello.glemo@gmail.com',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' atau kunjungi halaman Bantuan di aplikasi.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral700,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.neutral700,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}