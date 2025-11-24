import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class BantuanScreen extends ConsumerStatefulWidget {
  const BantuanScreen({super.key});

  @override
  ConsumerState<BantuanScreen> createState() => _BantuanScreenState();
}

class _BantuanScreenState extends ConsumerState<BantuanScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _faqList = [
    {
      'question': 'Bagaimana cara menggunakan fitur tracking jarak tempuh?',
      'answer': 'Untuk menggunakan fitur tracking, pastikan GPS aktif, lalu klik tombol "Mulai Perjalanan" di halaman Beranda. Sistem akan otomatis mencatat jarak tempuh Anda.'
    },
    {
      'question': 'Bagaimana cara mengatur jadwal servis motor?',
      'answer': 'Buka menu Monitoring, lalu pilih jenis servis yang ingin dijadwalkan. Anda dapat mengatur pengingat berdasarkan waktu atau jarak tempuh.'
    },
    {
      'question': 'Bagaimana cara mengganti data motor saya?',
      'answer': 'Masuk ke menu Profil, pilih "Motor Saya", kemudian Anda dapat melihat detail motor Anda. Untuk mengganti motor, hubungi tim support kami.'
    },
    {
      'question': 'Aplikasi tidak dapat mengakses GPS, apa yang harus dilakukan?',
      'answer': 'Pastikan Anda sudah memberikan izin akses lokasi ke aplikasi Glemo di pengaturan ponsel Anda. Jika masih bermasalah, coba restart aplikasi.'
    },
    {
      'question': 'Bagaimana cara melihat riwayat servis motor saya?',
      'answer': 'Buka menu Riwayat di navigasi bawah, lalu pilih tab "Servis" untuk melihat semua riwayat servis motor Anda.'
    },
    {
      'question': 'Apakah data saya aman di aplikasi Glemo?',
      'answer': 'Ya, kami menjaga keamanan data Anda dengan enkripsi dan mengikuti standar keamanan data yang ketat sesuai kebijakan privasi kami.'
    },
  ];

  List<Map<String, String>> _filteredFaqList = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqList = _faqList;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQ(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqList = _faqList;
      } else {
        _filteredFaqList = _faqList.where((faq) {
          return faq['question']!.toLowerCase().contains(query.toLowerCase()) ||
              faq['answer']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hello.glemo@gmail.com',
      query: 'subject=Bantuan Aplikasi Glemo',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/6281234567890');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bantuan',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      backgroundColor: AppColors.normalHover,
      body: Column(
        children: [
          Expanded(
            child: Container(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterFAQ,
                      decoration: InputDecoration(
                        hintText: 'Cari pertanyaan...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.neutral500,
                        ),
                        filled: true,
                        fillColor: AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.m),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.m,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      itemCount: _filteredFaqList.length,
                      itemBuilder: (context, index) {
                        return _buildFAQItem(
                          _filteredFaqList[index]['question']!,
                          _filteredFaqList[index]['answer']!,
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tidak menemukan jawaban?',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _launchEmail,
                                  icon: Icon(
                                    Icons.email_outlined,
                                    color: AppColors.normal,
                                  ),
                                  label: Text(
                                    'Email',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.normal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.normal),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.m),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _launchWhatsApp,
                                  icon: const Icon(
                                    Icons.chat_outlined,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'WhatsApp',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.normal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.m),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.m),
      title: Text(
        question,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.neutral900,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Text(
          answer,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral600,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}