import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/motor_details_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';

class MotorTypeScreen extends ConsumerStatefulWidget {
  final String model;

  const MotorTypeScreen({
    super.key,
    required this.model,
  });

  @override
  ConsumerState<MotorTypeScreen> createState() => _MotorTypeScreenState();
}

class _MotorTypeScreenState extends ConsumerState<MotorTypeScreen> {
  late TextEditingController _searchController;
  List<String> _motorTypes = [];
  List<String> _filteredTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMotorTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMotorTypes() async {
    try {
      // Query langsung dengan model (karena model == category di data Firestore)
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('motors')
          .where('category', isEqualTo: widget.model)
          .get();

      // Ambil motor_name dari setiap document
      final types = querySnapshot.docs
          .map((doc) => doc['motor_name'] as String? ?? doc.id)
          .toList();
      types.sort(); // Sort alphabetically

      setState(() {
        _motorTypes = types;
        _filteredTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMotorTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTypes = _motorTypes;
      } else {
        _filteredTypes = _motorTypes
            .where((type) => type.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jenis Motor ${widget.model}',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.neutral0),
        ),
        backgroundColor: AppColors.normalHover,
        iconTheme: const IconThemeData(color: AppColors.neutral0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkHover,
                    ),
                  )
                : _filteredTypes.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada data jenis motor',
                          style: AppTypography.bodyMedium,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                        child: ListView.builder(
                          itemCount: _filteredTypes.length,
                          itemBuilder: (context, index) {
                            final type = _filteredTypes[index];
                            return _MotorTypeItem(
                              title: type,
                              onTap: () {
                                ref.read(motorDetailsProvider.notifier).setType(type);
                                context.pop();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterMotorTypes,
      decoration: InputDecoration(
        hintText: 'Cari Jenis Motor',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.l),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      ),
    );
  }
}

class _MotorTypeItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _MotorTypeItem({
    required this.title,
    this.onTap,
  });

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
        child: Text(
          title,
          style: AppTypography.titleMedium,
        ),
      ),
    );
  }
}