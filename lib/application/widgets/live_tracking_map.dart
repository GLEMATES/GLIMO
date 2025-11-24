import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import '../themes/app_typography.dart';
import '../providers/gps_tracking_provider.dart';
import '../providers/trip_history_provider.dart';
import '../providers/motor_list_provider.dart';
import '../utils/geocoding_service.dart';
import '../services/notification_service.dart';

class LiveTrackingMap extends ConsumerStatefulWidget {
  const LiveTrackingMap({super.key});

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  MapType _currentMapType = MapType.normal;

  // Default location (Indonesia center) if location not available
  static const LatLng _defaultLocation = LatLng(-2.548926, 118.0148634);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location services disabled';
            _isLoading = false;
          });
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Location permission denied';
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location permission permanently denied';
            _isLoading = false;
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Note: No camera animation needed for preview card
        // Camera will be properly positioned via initialCameraPosition
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking Langsung',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.s),
        GestureDetector(
          onTap: () {
            context.push('/current-location');
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(AppSpacing.m),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Google Map
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.normalHover,
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 36,
                            color: AppColors.neutral500,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _getCurrentLocation();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Retry',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.normalHover,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  IgnorePointer(
                    child: GoogleMap(
                      key: const ValueKey('live_tracking_map'),
                      mapType: _currentMapType,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : _defaultLocation,
                        zoom: 16.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      markers: _currentPosition != null
                          ? {
                              Marker(
                                markerId: const MarkerId('current_location'),
                                position: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen,
                                ),
                                infoWindow: const InfoWindow(
                                  title: 'Lokasi Anda',
                                ),
                              ),
                            }
                          : {},
                      // Add polyline for tracking route
                      polylines: ref.watch(gpsTrackingProvider).positions.length >= 2
                          ? {
                              Polyline(
                                polylineId: const PolylineId('tracking_route'),
                                points: ref.watch(gpsTrackingProvider).getPolylinePoints(),
                                color: AppColors.normalHover,
                                width: 5,
                                startCap: Cap.roundCap,
                                endCap: Cap.roundCap,
                              ),
                            }
                          : {},
                    ),
                  ),

                // Map type selector button (show when tracking)
                if (ref.watch(gpsTrackingProvider).status == TrackingStatus.tracking)
                  Positioned(
                    top: AppSpacing.m,
                    right: AppSpacing.m,
                    child: GestureDetector(
                      onTap: _showMapTypeSelector,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.neutral0,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neutral900.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.layers,
                          color: AppColors.normalHover,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                // Tracking stats overlay (show when tracking)
                if (ref.watch(gpsTrackingProvider).status == TrackingStatus.tracking)
                  Positioned(
                    bottom: AppSpacing.m,
                    left: AppSpacing.m,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: AppColors.neutral0.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neutral900.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tracking',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ref.watch(gpsTrackingProvider).totalDistance.toStringAsFixed(2)} km',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                          Text(
                            ref.watch(gpsTrackingProvider).getFormattedDuration(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Tracking control buttons (below map)
        const SizedBox(height: AppSpacing.m),
        _buildTrackingControls(),
      ],
    );
  }

  Widget _buildTrackingControls() {
    final trackingState = ref.watch(gpsTrackingProvider);

    // Only show Stop button when tracking is active
    if (trackingState.status == TrackingStatus.tracking) {
      return ElevatedButton.icon(
        onPressed: () {
          _showStopTrackingDialog();
        },
        icon: const Icon(Icons.stop),
        label: const Text('Hentikan Tracking'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.neutral0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.m),
          ),
        ),
      );
    }

    // Hide button when idle (tracking controlled from "Mulai Perjalanan" button)
    return const SizedBox.shrink();
  }

  void _showMapTypeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Jenis Peta',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapTypeOption(
                dialogContext,
                'Normal',
                'Tampilan peta standar dengan jalan dan label',
                Icons.map,
                MapType.normal,
              ),
              const SizedBox(height: AppSpacing.s),
              _buildMapTypeOption(
                dialogContext,
                'Satelit',
                'Tampilan foto satelit',
                Icons.satellite_alt,
                MapType.satellite,
              ),
              const SizedBox(height: AppSpacing.s),
              _buildMapTypeOption(
                dialogContext,
                'Terrain',
                'Tampilan kontur dan ketinggian',
                Icons.terrain,
                MapType.terrain,
              ),
              const SizedBox(height: AppSpacing.s),
              _buildMapTypeOption(
                dialogContext,
                'Hybrid',
                'Satelit dengan label jalan',
                Icons.layers,
                MapType.hybrid,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption(
    BuildContext dialogContext,
    String title,
    String description,
    IconData icon,
    MapType mapType,
  ) {
    final isSelected = _currentMapType == mapType;

    return GestureDetector(
      onTap: () {
        Navigator.of(dialogContext).pop();
        // Use post-frame callback to ensure setState happens after dialog is closed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentMapType = mapType;
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.normalHover.withValues(alpha: 0.1)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.s),
          border: Border.all(
            color: isSelected ? AppColors.normalHover : AppColors.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.normalHover
                    : AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.neutral0 : AppColors.neutral700,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.normalHover
                          : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.normalHover,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showStopTrackingDialog() {
    final trackingNotifier = ref.read(gpsTrackingProvider.notifier);
    final meetsRequirements = trackingNotifier.meetsMinimumRequirements();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Hentikan Tracking?',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meetsRequirements
                    ? 'Apakah Anda ingin menyimpan perjalanan ini?'
                    : 'Perjalanan tidak memenuhi syarat minimum untuk disimpan.',
                style: AppTypography.bodyLarge,
              ),
              if (!meetsRequirements) ...[
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.s),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    trackingNotifier.getRequirementsMessage(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(gpsTrackingProvider.notifier).resetTracking();
                    Navigator.of(dialogContext).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.m),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  ),
                  child: const Text('Buang'),
                ),
                const SizedBox(width: AppSpacing.m),
                if (meetsRequirements)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _showSaveTripDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    ),
                    child: const Text('Simpan Perjalanan'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      ref.read(gpsTrackingProvider.notifier).resumeTracking();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.normalHover,
                      foregroundColor: AppColors.neutral0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    ),
                    child: const Text('Lanjutkan'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showSaveTripDialog() {
    final motors = ref.read(motorListProvider);

    if (motors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada motor. Silakan tambahkan motor terlebih dahulu.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral0,
              fontWeight: FontWeight.w600,
            ),
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
      ref.read(gpsTrackingProvider.notifier).resetTracking();
      return;
    }

    // Get active motor first
    Motor? selectedMotor = ref.read(motorListProvider.notifier).getActiveMotor();
    if (selectedMotor == null && motors.isNotEmpty) {
      selectedMotor = motors.first;
    }

    // Get tracking summary to calculate odometer
    final trackingSummary = ref.read(gpsTrackingProvider.notifier).getTrackingSummary();
    final gpsDistance = (trackingSummary['distance'] as double? ?? 0.0);

    // Auto-fill odometer values
    // Start odometer = current motor odometer
    final currentOdometer = int.tryParse(selectedMotor?.odometer ?? '0') ?? 0;
    // End odometer = current odometer + GPS distance (rounded up)
    final calculatedEndOdometer = currentOdometer + gpsDistance.ceil();

    final startOdometerController = TextEditingController(text: currentOdometer.toString());
    final endOdometerController = TextEditingController(text: calculatedEndOdometer.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Simpan Perjalanan GPS',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card showing GPS distance
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.normalHover.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.s),
                        border: Border.all(
                          color: AppColors.normalHover.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.normalHover,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              'Jarak GPS: ${gpsDistance.toStringAsFixed(2)} km\nOdometer otomatis dihitung dari GPS tracking',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.normalHover,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Motor',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Motor>(
                          value: selectedMotor,
                          isExpanded: true,
                          items: motors.map((motor) {
                            return DropdownMenuItem<Motor>(
                              value: motor,
                              child: Text('${motor.model} - ${motor.type}'),
                            );
                          }).toList(),
                          onChanged: (Motor? newValue) {
                            setState(() {
                              selectedMotor = newValue;
                              // Recalculate odometer when motor changes
                              final newOdometer = int.tryParse(newValue?.odometer ?? '0') ?? 0;
                              final newEndOdometer = newOdometer + gpsDistance.ceil();
                              startOdometerController.text = newOdometer.toString();
                              endOdometerController.text = newEndOdometer.toString();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Odometer Awal (km) - Otomatis',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: startOdometerController,
                      keyboardType: TextInputType.number,
                      enabled: false,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                          borderSide: BorderSide(color: AppColors.neutral300),
                        ),
                        hintText: 'Otomatis dari Total Jarak Tempuh',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Odometer Akhir (km) - Otomatis',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: endOdometerController,
                      keyboardType: TextInputType.number,
                      enabled: false,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.s),
                          borderSide: BorderSide(color: AppColors.neutral300),
                        ),
                        hintText: 'Odometer Awal + Jarak GPS',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        ref.read(gpsTrackingProvider.notifier).resetTracking();
                      },
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
                    if (selectedMotor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pilih motor terlebih dahulu',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.neutral0,
                              fontWeight: FontWeight.w600,
                            ),
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

                    // Odometer values are auto-calculated, just parse them
                    final startOdo = int.tryParse(startOdometerController.text) ?? 0;
                    final endOdo = int.tryParse(endOdometerController.text) ?? 0;

                    // Convert positions to route points and sort by timestamp
                    final routePoints = (trackingSummary['positions'] as List).map((pos) {
                      return {
                        'latitude': pos['latitude'],
                        'longitude': pos['longitude'],
                        'timestamp': pos['timestamp'],
                      };
                    }).toList();

                    debugPrint('💾 [SAVE] ========================================');
                    debugPrint('💾 [SAVE] Saving GPS trip with ${routePoints.length} points');
                    debugPrint('💾 [SAVE] BEFORE sort - First point timestamp: ${routePoints.first['timestamp']}');
                    debugPrint('💾 [SAVE] BEFORE sort - Last point timestamp: ${routePoints.last['timestamp']}');

                    routePoints.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

                    debugPrint('💾 [SAVE] AFTER sort - First point timestamp: ${routePoints.first['timestamp']}');
                    debugPrint('💾 [SAVE] AFTER sort - Last point timestamp: ${routePoints.last['timestamp']}');
                    debugPrint('💾 [SAVE] First point: ${routePoints.first['latitude']}, ${routePoints.first['longitude']}');
                    debugPrint('💾 [SAVE] Last point: ${routePoints.last['latitude']}, ${routePoints.last['longitude']}');
                    debugPrint('💾 [SAVE] Trip START: ${trackingSummary['startLatitude']}, ${trackingSummary['startLongitude']}');
                    debugPrint('💾 [SAVE] Trip END: ${trackingSummary['endLatitude']}, ${trackingSummary['endLongitude']}');

                    final totalDuration = trackingSummary['duration'] as int;
                    final gaps = <Map<String, dynamic>>[];

                    for (int i = 1; i < routePoints.length; i++) {
                      final prevTimestamp = routePoints[i - 1]['timestamp'] as int;
                      final currTimestamp = routePoints[i]['timestamp'] as int;
                      final gap = (currTimestamp - prevTimestamp) / 1000;

                      if (gap > 60) {
                        gaps.add({
                          'from': i - 1,
                          'to': i,
                          'seconds': gap,
                        });
                        debugPrint('⚠️ [SAVE] Large gap detected: Point[${i-1}] → Point[$i] = ${gap.toInt()} seconds');
                      }
                    }

                    int totalGapSeconds = 0;
                    for (var gap in gaps) {
                      totalGapSeconds += (gap['seconds'] as double).toInt();
                    }

                    final coverage = totalDuration > 0 ? ((totalDuration - totalGapSeconds) / totalDuration * 100) : 100.0;

                    debugPrint('📊 [SAVE] GPS Coverage: ${coverage.toStringAsFixed(1)}% (${gaps.length} gaps, ${totalGapSeconds}s missing)');
                    debugPrint('💾 [SAVE] ========================================');

                    if (coverage < 70 || gaps.isNotEmpty) {
                      if (!dialogContext.mounted) return;

                      final shouldContinue = await showDialog<bool>(
                        context: dialogContext,
                        builder: (BuildContext alertContext) {
                          return AlertDialog(
                            title: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                                const SizedBox(width: AppSpacing.s),
                                Text(
                                  'Data GPS Kurang Lengkap',
                                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.m),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.s),
                                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cakupan Data: ${coverage.toStringAsFixed(1)}%',
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.warning,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Ditemukan ${gaps.length} celah besar dalam rekaman GPS',
                                          style: AppTypography.bodyMedium,
                                        ),
                                        if (gaps.isNotEmpty) ...[
                                          const SizedBox(height: AppSpacing.s),
                                          ...gaps.map((gap) {
                                            final seconds = (gap['seconds'] as double).toInt();
                                            final minutes = seconds ~/ 60;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Text(
                                                '• Celah ${minutes}m ${seconds % 60}s',
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: AppColors.neutral700,
                                                ),
                                              ),
                                            );
                                          }).take(3),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  Text(
                                    'Kemungkinan Penyebab:',
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '• HP di-lock terlalu lama\n'
                                    '• Battery optimization kill background service\n'
                                    '• Sinyal GPS lemah di area tertentu\n'
                                    '• App di-force stop dari notification',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.neutral700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.m),
                                    decoration: BoxDecoration(
                                      color: AppColors.normalHover.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.s),
                                      border: Border.all(color: AppColors.normalHover.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.lightbulb_outline, size: 16, color: AppColors.normalHover),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tips untuk tracking berikutnya:',
                                              style: AppTypography.bodySmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.normalHover,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '• Matikan battery optimization untuk GLIMO\n'
                                          '• Pastikan notifikasi tracking tetap aktif\n'
                                          '• Jangan swipe hapus notifikasi tracking',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.neutral700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  Text(
                                    'Replay animasi mungkin akan terlihat "lompat-lompat" karena data tidak lengkap.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.neutral600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actionsPadding: const EdgeInsets.only(bottom: AppSpacing.l, right: AppSpacing.l, left: AppSpacing.l),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(alertContext).pop(false);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.m),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                                      ),
                                      child: const Text('Buang Data'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(alertContext).pop(true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.normalHover,
                                        foregroundColor: AppColors.neutral0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.m),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                                      ),
                                      child: const Text('Tetap Simpan'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldContinue != true) {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        ref.read(gpsTrackingProvider.notifier).resetTracking();
                        return;
                      }
                    }

                    // Save parent context reference
                    final parentContext = context;

                    try {
                      // Get start and end addresses
                      final startAddress = await GeocodingService.getShortAddress(
                        latitude: trackingSummary['startLatitude'],
                        longitude: trackingSummary['startLongitude'],
                      );

                      final endAddress = await GeocodingService.getShortAddress(
                        latitude: trackingSummary['endLatitude'],
                        longitude: trackingSummary['endLongitude'],
                      );

                      // Save trip to Firestore
                      await ref.read(tripHistoryProvider.notifier).addGPSTrip(
                        motorId: selectedMotor!.id,
                        motorName: '${selectedMotor!.model} - ${selectedMotor!.type}',
                        startOdometer: startOdo,
                        endOdometer: endOdo,
                        startLocation: startAddress,
                        endLocation: endAddress,
                        startLat: trackingSummary['startLatitude'],
                        startLng: trackingSummary['startLongitude'],
                        endLat: trackingSummary['endLatitude'],
                        endLng: trackingSummary['endLongitude'],
                        routePoints: routePoints,
                        duration: trackingSummary['duration'],
                        gpsDistance: trackingSummary['distance'] as double?,
                      );

                      // Stop tracking and reset
                      await ref.read(gpsTrackingProvider.notifier).resetTracking();

                      // Clear saved tracking data
                      await ref.read(gpsTrackingProvider.notifier).clearSavedTracking();

                      // Send trip completion notification
                      try {
                        final distance = trackingSummary['distance'] as double? ?? 0.0;
                        final durationSeconds = trackingSummary['duration'] as int? ?? 0;
                        final duration = Duration(seconds: durationSeconds);
                        final hours = duration.inHours;
                        final minutes = duration.inMinutes.remainder(60);

                        String durationText;
                        if (hours > 0) {
                          durationText = '${hours}h ${minutes}m';
                        } else {
                          durationText = '${minutes}m';
                        }

                        await NotificationService().showTripCompletionNotification(
                          motorName: '${selectedMotor!.model} - ${selectedMotor!.type}',
                          distance: distance,
                          duration: durationText,
                          isAutoMode: false,
                        );
                      } catch (e) {
                        debugPrint('Failed to send trip completion notification: $e');
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }

                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Trip berhasil disimpan!',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral0,
                                fontWeight: FontWeight.w600,
                              ),
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
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }

                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${e.toString()}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.neutral0,
                                fontWeight: FontWeight.w600,
                              ),
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
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}