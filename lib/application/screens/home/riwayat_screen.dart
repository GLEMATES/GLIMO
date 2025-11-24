import 'package:flutter/material.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_typography.dart';
import '../../widgets/history_tab.dart';
import '../../widgets/service_history_tab.dart';

class RiwayatScreen extends StatefulWidget {
  final int initialTabIndex;

  const RiwayatScreen({super.key, this.initialTabIndex = 0});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        backgroundColor: AppColors.normalHover,
        title: Text(
          'Riwayat',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.neutral0,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedIndex == 0
                                ? AppColors.normal
                                : Colors.transparent,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: AppColors.neutral300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Riwayat Servis',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedIndex == 0
                              ? AppColors.neutral900
                              : AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedIndex == 1
                                ? AppColors.normal
                                : Colors.transparent,
                            width: 4,
                          ),
                          left: BorderSide(
                            color: AppColors.neutral300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Riwayat Perjalanan',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedIndex == 1
                              ? AppColors.neutral900
                              : AppColors.neutral500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? const ServiceHistoryTab()
                : const HistoryTab(),
          ),
        ],
      ),
    );
  }
}