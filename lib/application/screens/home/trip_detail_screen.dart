import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_spacing.dart';
import '../../themes/app_typography.dart';
import '../../providers/trip_history_provider.dart';
import '../../utils/gpx_exporter.dart';
import '../../utils/geocoding_service.dart';

class TripDetailScreen extends StatefulWidget {
  final TripHistory trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  AnimationController? _replayController;
  Animation<double>? _replayAnimation;
  bool _isReplaying = false;
  String? _startAddress;
  String? _endAddress;
  bool _isLoadingAddresses = false;
  final ValueNotifier<Offset?> _replayScreenPositionNotifier = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();

    // Fetch addresses if not available
    _loadAddresses();

    // Initialize replay animation if GPS trip with route data
    if (widget.trip.source == 'gps' &&
        widget.trip.routePoints != null &&
        widget.trip.routePoints!.isNotEmpty) {
      final duration = widget.trip.duration ?? 30; // Default 30 seconds
      final replayDuration = (duration / 10).clamp(5, 30).toInt(); // 10x speed, max 30s

      _replayController = AnimationController(
        duration: Duration(seconds: replayDuration),
        vsync: this,
      );

      _replayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _replayController!, curve: Curves.linear),
      );

      _replayAnimation!.addListener(() async {
        if (_isReplaying && widget.trip.routePoints != null && _mapController != null) {
          final routePoints = List<Map<String, dynamic>>.from(widget.trip.routePoints!);

          routePoints.sort((a, b) {
            final timestampA = a['timestamp'] as int? ?? 0;
            final timestampB = b['timestamp'] as int? ?? 0;
            return timestampA.compareTo(timestampB);
          });

          final polylinePoints = routePoints.map((point) {
            return LatLng(
              (point['latitude'] as num).toDouble(),
              (point['longitude'] as num).toDouble(),
            );
          }).toList();

          final progress = _replayAnimation!.value;
          final latLngPosition = _getReplayPosition(polylinePoints);

          final progressPercent = (progress * 100).round();
          if (progressPercent % 10 == 0 && (progressPercent == 0 || progressPercent == 10 || progressPercent == 25 || progressPercent == 50 || progressPercent == 75 || progressPercent == 100)) {
            debugPrint('📍 [REPLAY] Progress $progressPercent%: ${latLngPosition.latitude.toStringAsFixed(6)}, ${latLngPosition.longitude.toStringAsFixed(6)}');
          }

          try {
            final screenCoord = await _mapController!.getScreenCoordinate(latLngPosition);
            final newScreenPos = Offset(
              screenCoord.x.toDouble(),
              screenCoord.y.toDouble(),
            );

            final oldScreenPos = _replayScreenPositionNotifier.value;
            if (progressPercent == 0 || progressPercent == 25 || progressPercent == 50 || progressPercent == 75 || progressPercent == 100) {
              debugPrint('🖥️ [REPLAY] Screen position: ${newScreenPos.dx.toStringAsFixed(1)}, ${newScreenPos.dy.toStringAsFixed(1)}');
              if (oldScreenPos != null) {
                final distance = (newScreenPos - oldScreenPos).distance;
                debugPrint('🖥️ [REPLAY] Moved ${distance.toStringAsFixed(1)} pixels from last position');
              }
            }

            _replayScreenPositionNotifier.value = newScreenPos;
          } catch (e) {
            debugPrint('❌ [REPLAY] Error getting screen coordinate: $e');
          }
        }
      });

      _replayController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isReplaying = false;
            _replayScreenPositionNotifier.value = null;
          });
        }
      });
    }
  }

  Future<void> _loadAddresses() async {
    // Use saved addresses if available
    if (widget.trip.startLocation != null && widget.trip.endLocation != null) {
      setState(() {
        _startAddress = widget.trip.startLocation;
        _endAddress = widget.trip.endLocation;
      });
      return;
    }

    // Otherwise, fetch via geocoding
    if (widget.trip.startLat != null && widget.trip.startLng != null) {
      setState(() {
        _isLoadingAddresses = true;
      });

      final startAddr = await GeocodingService.getShortAddress(
        latitude: widget.trip.startLat!,
        longitude: widget.trip.startLng!,
      );

      final endAddr = await GeocodingService.getShortAddress(
        latitude: widget.trip.endLat!,
        longitude: widget.trip.endLng!,
      );

      if (mounted) {
        setState(() {
          _startAddress = startAddr;
          _endAddress = endAddr;
          _isLoadingAddresses = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _replayController?.dispose();
    _replayScreenPositionNotifier.dispose();
    super.dispose();
  }

  void _toggleReplay() {
    if (_replayController == null) return;

    setState(() {
      if (_isReplaying) {
        _replayController!.stop();
        _replayScreenPositionNotifier.value = null;
        _isReplaying = false;
        debugPrint('🛑 [REPLAY] Replay STOPPED');
      } else {
        debugPrint('🎬 [REPLAY] ========================================');
        debugPrint('🎬 [REPLAY] Starting replay animation');

        if (widget.trip.routePoints != null && widget.trip.routePoints!.isNotEmpty && _mapController != null) {
          final routePoints = List<Map<String, dynamic>>.from(widget.trip.routePoints!);

          debugPrint('🎬 [REPLAY] BEFORE sort - All timestamps:');
          for (int i = 0; i < routePoints.length; i++) {
            debugPrint('   Point[$i]: ${routePoints[i]['timestamp']} (${routePoints[i]['latitude']}, ${routePoints[i]['longitude']})');
          }

          routePoints.sort((a, b) {
            final timestampA = a['timestamp'] as int? ?? 0;
            final timestampB = b['timestamp'] as int? ?? 0;
            return timestampA.compareTo(timestampB);
          });

          debugPrint('🎬 [REPLAY] AFTER sort - All timestamps:');
          bool isSortedCorrectly = true;
          for (int i = 0; i < routePoints.length; i++) {
            debugPrint('   Point[$i]: ${routePoints[i]['timestamp']} (${routePoints[i]['latitude']}, ${routePoints[i]['longitude']})');
            if (i > 0) {
              final prevTimestamp = routePoints[i - 1]['timestamp'] as int;
              final currTimestamp = routePoints[i]['timestamp'] as int;
              if (currTimestamp < prevTimestamp) {
                isSortedCorrectly = false;
                debugPrint('   ⚠️ WARNING: Point[$i] timestamp SMALLER than Point[${i-1}]!');
              }
            }
          }

          if (isSortedCorrectly) {
            debugPrint('✅ [REPLAY] All timestamps are in ASCENDING order');
          } else {
            debugPrint('❌ [REPLAY] Timestamps are NOT in correct order!');
          }

          final firstPoint = routePoints.first;
          final lastPoint = routePoints.last;

          debugPrint('🎬 [REPLAY] Total route points: ${routePoints.length}');
          debugPrint('🎬 [REPLAY] First point: ${firstPoint['latitude']}, ${firstPoint['longitude']} (timestamp: ${firstPoint['timestamp']})');
          debugPrint('🎬 [REPLAY] Last point: ${lastPoint['latitude']}, ${lastPoint['longitude']} (timestamp: ${lastPoint['timestamp']})');

          if (widget.trip.startLat != null && widget.trip.endLat != null) {
            debugPrint('🎬 [REPLAY] Trip START location: ${widget.trip.startLat}, ${widget.trip.startLng}');
            debugPrint('🎬 [REPLAY] Trip END location: ${widget.trip.endLat}, ${widget.trip.endLng}');

            final distFirstToStart = ((firstPoint['latitude'] as num).toDouble() - widget.trip.startLat!).abs() +
                                     ((firstPoint['longitude'] as num).toDouble() - widget.trip.startLng!).abs();
            final distLastToEnd = ((lastPoint['latitude'] as num).toDouble() - widget.trip.endLat!).abs() +
                                  ((lastPoint['longitude'] as num).toDouble() - widget.trip.endLng!).abs();

            debugPrint('🎬 [REPLAY] Distance first→start: ${distFirstToStart.toStringAsFixed(6)}');
            debugPrint('🎬 [REPLAY] Distance last→end: ${distLastToEnd.toStringAsFixed(6)}');

            if (distFirstToStart < 0.001 && distLastToEnd < 0.001) {
              debugPrint('✅ [REPLAY] Route direction: CORRECT (first→start, last→end)');
            } else {
              debugPrint('⚠️ [REPLAY] Route direction: MIGHT BE REVERSED!');
            }
          }

          final initialLatLng = LatLng(
            (firstPoint['latitude'] as num).toDouble(),
            (firstPoint['longitude'] as num).toDouble(),
          );

          _mapController!.getScreenCoordinate(initialLatLng).then((screenCoord) async {
            _replayScreenPositionNotifier.value = Offset(
              screenCoord.x.toDouble(),
              screenCoord.y.toDouble(),
            );
            debugPrint('🏁 [REPLAY] Initial motor position SET at: ${initialLatLng.latitude}, ${initialLatLng.longitude}');
            debugPrint('🏁 [REPLAY] Initial screen position: ${screenCoord.x}, ${screenCoord.y}');

            await Future.delayed(const Duration(milliseconds: 100));

            if (mounted && _replayController != null) {
              _replayController!.reset();
              _replayController!.forward();
              debugPrint('▶️ [REPLAY] Animation STARTED');
            }
          });
        } else {
          _replayController!.reset();
          _replayController!.forward();
        }

        debugPrint('🎬 [REPLAY] ========================================');
        _isReplaying = true;
      }
    });
  }

  LatLng _getReplayPosition(List<LatLng> polylinePoints) {
    if (_replayAnimation == null || polylinePoints.isEmpty) {
      return polylinePoints.first;
    }

    final progress = _replayAnimation!.value;
    final totalPoints = polylinePoints.length;
    final currentIndex = (progress * (totalPoints - 1)).floor();
    final nextIndex = (currentIndex + 1).clamp(0, totalPoints - 1);

    if (currentIndex >= totalPoints - 1) {
      return polylinePoints.last;
    }

    // Interpolate between current and next point
    final currentPoint = polylinePoints[currentIndex];
    final nextPoint = polylinePoints[nextIndex];
    final segmentProgress = (progress * (totalPoints - 1)) - currentIndex;

    final lat = currentPoint.latitude +
                (nextPoint.latitude - currentPoint.latitude) * segmentProgress;
    final lng = currentPoint.longitude +
                (nextPoint.longitude - currentPoint.longitude) * segmentProgress;

    return LatLng(lat, lng);
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'N/A';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  double? _calculateAvgSpeed() {
    if (widget.trip.duration == null || widget.trip.duration == 0) return null;

    // distance in km, duration in seconds
    final hours = widget.trip.duration! / 3600;
    return widget.trip.distance / hours;
  }

  Future<void> _shareTrip() async {
    try {
      final trip = widget.trip;
      final avgSpeed = _calculateAvgSpeed();

      // Create text summary
      final buffer = StringBuffer();
      buffer.writeln('🏍️ ${trip.motorName}');
      buffer.writeln('');
      buffer.writeln('📅 ${_formatDate(trip.date)}');
      buffer.writeln('📊 Jarak: ${trip.getFormattedDistance()}');
      buffer.writeln('🎯 Odometer: ${trip.startOdometer} km → ${trip.endOdometer} km');

      if (trip.source == 'gps') {
        buffer.writeln('');
        buffer.writeln('⏱️ Durasi: ${_formatDuration(trip.duration)}');
        if (avgSpeed != null) {
          buffer.writeln('🏁 Kecepatan Rata-rata: ${avgSpeed.toStringAsFixed(1)} km/h');
        }
        if (trip.routePoints != null) {
          buffer.writeln('📍 Waypoints: ${trip.routePoints!.length} titik');
        }
      }

      buffer.writeln('');
      buffer.writeln('📱 Recorded with GLIMO App');

      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString(),
          subject: 'Trip: ${trip.motorName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing trip: $e',
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
  }

  Future<void> _exportGPX() async {
    try {
      if (widget.trip.source != 'gps') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hanya trip GPS yang bisa di-export ke GPX',
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

      // Generate GPX content
      final gpxContent = GPXExporter.generateGPX(widget.trip);
      final filename = GPXExporter.generateFilename(widget.trip);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');

      // Write GPX file
      await file.writeAsString(gpxContent);

      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          text: 'Route data exported from GLIMO App',
          subject: 'GPX Export: ${widget.trip.motorName}',
          files: [XFile(file.path)],
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPX file exported: $filename',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error exporting GPX: $e',
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
  }

  @override
  Widget build(BuildContext context) {
    final isGPSTrip = widget.trip.source == 'gps';
    final hasRouteData = widget.trip.routePoints != null &&
                        widget.trip.routePoints!.isNotEmpty;
    final avgSpeed = _calculateAvgSpeed();

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        backgroundColor: AppColors.normalHover,
        title: Text(
          'Detail Perjalanan',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.neutral0,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.neutral0),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTrip,
            tooltip: 'Share Trip',
          ),
          // Export GPX button (only for GPS trips)
          if (isGPSTrip && hasRouteData)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportGPX,
              tooltip: 'Export GPX',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section (only for GPS trips with route data)
            if (isGPSTrip && hasRouteData) _buildMapSection(),

            // Trip Info Section
            _buildTripInfoSection(),

            // Statistics Section
            if (isGPSTrip) _buildStatisticsSection(avgSpeed),

            // GPS Data Section
            if (isGPSTrip) _buildGPSDataSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    final routePoints = List<Map<String, dynamic>>.from(widget.trip.routePoints!);

    routePoints.sort((a, b) {
      final timestampA = a['timestamp'] as int? ?? 0;
      final timestampB = b['timestamp'] as int? ?? 0;
      return timestampA.compareTo(timestampB);
    });

    final polylinePoints = routePoints.map((point) {
      return LatLng(
        (point['latitude'] as num).toDouble(),
        (point['longitude'] as num).toDouble(),
      );
    }).toList();

    debugPrint('🗺️ [MAP] Building map with ${polylinePoints.length} points');
    debugPrint('🗺️ [MAP] First point: ${polylinePoints.first.latitude}, ${polylinePoints.first.longitude}');
    debugPrint('🗺️ [MAP] Last point: ${polylinePoints.last.latitude}, ${polylinePoints.last.longitude}');

    // Calculate bounds to fit all points
    LatLngBounds? bounds;
    if (polylinePoints.length >= 2) {
      double minLat = polylinePoints.first.latitude;
      double maxLat = polylinePoints.first.latitude;
      double minLng = polylinePoints.first.longitude;
      double maxLng = polylinePoints.first.longitude;

      for (var point in polylinePoints) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.m),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            key: ValueKey('trip_detail_map_${widget.trip.id}'),
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: polylinePoints.first,
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              if (bounds != null) {
                Future.delayed(const Duration(milliseconds: 500), () async {
                  if (mounted && _mapController != null) {
                    try {
                      await _mapController!.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds!, 50),
                      );
                    } catch (e) {
                      debugPrint('Camera animation error: $e');
                    }
                  }
                });
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: polylinePoints.first,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
                infoWindow: const InfoWindow(title: 'Mulai'),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: polylinePoints.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
                infoWindow: const InfoWindow(title: 'Selesai'),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: AppColors.normalHover,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            },
          ),
          if (_isReplaying)
            ValueListenableBuilder<Offset?>(
              valueListenable: _replayScreenPositionNotifier,
              builder: (context, screenPos, child) {
                if (screenPos == null) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: screenPos.dx - 20,
                  top: screenPos.dy - 20,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.normalHover,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.motorcycle,
                        size: 24,
                        color: AppColors.neutral0,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Replay control button
          if (_replayController != null)
            Positioned(
              bottom: AppSpacing.m,
              right: AppSpacing.m,
              child: FloatingActionButton.small(
                onPressed: _toggleReplay,
                backgroundColor: AppColors.normalHover,
                child: Icon(
                  _isReplaying ? Icons.stop : Icons.play_arrow,
                  color: AppColors.neutral0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfoSection() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.m),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.normalHover,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Informasi Perjalanan',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          _buildInfoRow('Motor', widget.trip.motorName),
          _buildInfoRow('Tanggal', _formatDate(widget.trip.date)),
          _buildInfoRow('Sumber Data', widget.trip.source == 'gps' ? 'GPS Tracking' : 'Manual Input'),
          const Divider(height: AppSpacing.l),
          _buildInfoRow('Odometer Awal', '${widget.trip.startOdometer} km'),
          _buildInfoRow('Odometer Akhir', '${widget.trip.endOdometer} km'),
          _buildInfoRow(
            'Jarak Tempuh',
            widget.trip.getFormattedDistance(),
            valueColor: AppColors.normalHover,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(double? avgSpeed) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.m),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.normalHover,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Statistik',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_outlined,
                  label: 'Durasi',
                  value: _formatDuration(widget.trip.duration),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.speed,
                  label: 'Rata-rata',
                  value: avgSpeed != null
                      ? '${avgSpeed.toStringAsFixed(1)} km/h'
                      : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGPSDataSection() {
    final hasRouteData = widget.trip.routePoints != null &&
                        widget.trip.routePoints!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.circular(AppSpacing.m),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: AppColors.normalHover,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Data GPS',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (_startAddress != null)
            _buildInfoRow('Lokasi Awal', _startAddress!),
          if (_endAddress != null)
            _buildInfoRow('Lokasi Akhir', _endAddress!),
          if (_isLoadingAddresses && _startAddress == null)
            _buildInfoRow('Lokasi', 'Memuat alamat...'),
          if (hasRouteData)
            _buildInfoRow(
              'Total Waypoints',
              '${widget.trip.routePoints!.length} titik',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? AppColors.neutral900,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.normalHover.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.s),
        border: Border.all(
          color: AppColors.normalHover.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.normalHover,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.normalHover,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
