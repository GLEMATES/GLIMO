import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        backgroundColor: AppColors.normalHover,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.neutral0,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Syarat dan Ketentuan',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendahuluan',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Privasi Anda penting bagi kami. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, melindungi, dan mengelola informasi pribadi Anda saat Anda menggunakan aplikasi Glemo. Dengan menggunakan aplikasi kami, Anda menyetujui pengumpulkan dan penggunaan informasi sebagaimana diatur dalam kebijakan ini.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Informasi yang Kami Kumpulkan',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Kami dapat mengumpulkan jenis informasi berikut untuk meningkatkan pengalaman Anda:',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildBulletPoint(
                    'Informasi Pribadi: Nama, alamat email, atau informasi lain yang Anda berikan secara sukarela.',
                  ),
                  _buildBulletPoint(
                    'Informasi Perangkat: Model perangkat, sistem operasi, jenis browser, alamat IP, dan pengenal perangkat unik.',
                  ),
                  _buildBulletPoint(
                    'Data Lokasi: Jika Anda memberikan izin, kami dapat mengumpulkan informasi lokasi untuk fitur berbasis lokasi.',
                  ),
                  _buildBulletPoint(
                    'Data Penggunaan: Informasi tentang cara Anda berinteraksi dengan aplikasi, seperti fitur yang sering digunakan, waktu penggunaan, dan halaman yang diakses.',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Cara Kami Menggunakan Informasi Anda',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Informasi yang kami kumpulkan digunakan untuk:',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildBulletPoint(
                    'Menyediakan, mengelola, dan meningkatkan layanan kami.',
                  ),
                  _buildBulletPoint(
                    'Meningkatkan pengalaman pengguna melalui personalisasi fitur.',
                  ),
                  _buildBulletPoint(
                    'Menyediakan dukungan teknis dan menjawab pertanyaan Anda.',
                  ),
                  _buildBulletPoint(
                    'Mengirimkan pembaruan penting, seperti perubahan kebijakan atau fitur baru.',
                  ),
                  _buildBulletPoint(
                    'Mematuhi kewajiban hukum atau peraturan yang berlaku.',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Penyimpanan dan Keamanan Data',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Kami menyimpan data Anda dengan aman menggunakan teknologi enkripsi dan langkah-langkah keamanan untuk mencegah akses, perubahan, pengungkapan, atau penghancuran data tanpa izin. Namun, kami tidak dapat menjamin keamanan absolut terhadap serangan siber atau pelanggaran data.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Pembagian Informasi dengan Pihak Ketiga',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Kami tidak membagikan informasi pribadi Anda kepada pihak ketiga, kecuali dalam keadaan berikut:',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildBulletPoint(
                    'Jika Anda memberikan izin eksplisit.',
                  ),
                  _buildBulletPoint(
                    'Jika diperlukan oleh hukum atau peraturan yang berlaku.',
                  ),
                  _buildBulletPoint(
                    'Jika diperlukan untuk melindungi hak, properti, atau keselamatan pengguna kami dan aplikasi kami.',
                  ),
                  _buildBulletPoint(
                    'Jika kami bekerja dengan mitra atau penyedia layanan untuk membantu operasi aplikasi (misalnya, analitik atau pengolahan pembayaran), dengan ketentuan mereka mematuhi kebijakan privasi kami.',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Hak Anda',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Sebagai pengguna, Anda memiliki hak untuk:',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _buildBulletPoint(
                    'Mengakses informasi pribadi Anda yang kami simpan.',
                  ),
                  _buildBulletPoint(
                    'Meminta koreksi atas data yang tidak akurat atau tidak lengkap.',
                  ),
                  _buildBulletPoint(
                    'Meminta penghapusan data Anda, kecuali jika data tersebut diperlukan untuk tujuan hukum atau operasional.',
                  ),
                  _buildBulletPoint(
                    'Menolak pemrosesan data Anda untuk tujuan tertentu, seperti pemasaran.',
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Perubahan Kebijakan Privasi',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu. Perubahan akan diinformasikan melalui aplikasi kami. Kami mendorong Anda untuk meninjau kebijakan ini secara berkala untuk tetap mengetahui bagaimana kami melindungi data Anda.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    'Hubungi Kami',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Jika Anda memiliki pertanyaan, keluhan, atau ingin menggunakan hak privasi Anda, silakan hubungi kami melalui:',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Email: hello.glemo@gmail.com',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.neutral0,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neutral900.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (value) {
                        setState(() {
                          _isAgreed = value ?? false;
                        });
                      },
                      activeColor: AppColors.normalHover,
                    ),
                    Expanded(
                      child: Text(
                        'Saya mengerti dan menyetujui Syarat dan Ketentuan dan Pemberitahuan Privasi yang berlaku.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.xxl),
                    color: _isAgreed ? AppColors.normalHover : AppColors.neutral300,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isAgreed
                          ? () {
                              Navigator.of(context).pop(true);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(AppSpacing.xxl),
                      child: Center(
                        child: Text(
                          'Setuju',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.neutral0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.m, bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.bodyMedium,
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}