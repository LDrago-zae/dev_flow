import 'package:flutter/material.dart';
import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:dev_flow/services/location_service.dart';

class TaskLocationMapScreen extends StatefulWidget {
  final String locationName;
  final double latitude;
  final double longitude;
  final String taskTitle;

  const TaskLocationMapScreen({
    super.key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.taskTitle,
  });

  @override
  State<TaskLocationMapScreen> createState() => _TaskLocationMapScreenState();
}

class _TaskLocationMapScreenState extends State<TaskLocationMapScreen> {
  MapboxMap? _mapboxMap;
  final LocationService _locationService = LocationService();
  double? _currentLatitude;
  double? _currentLongitude;
  String? _distance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;

        final distanceInMeters = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          widget.latitude,
          widget.longitude,
        );
        _distance = _locationService.formatDistance(distanceInMeters);
      });
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _setupMap();
  }

  Future<void> _setupMap() async {
    if (_mapboxMap == null) return;

    // Enable location puck with pulsing animation
    await _enableLocationPuck();

    // Add marker for task location
    await _addTaskMarker();
  }

  Future<void> _enableLocationPuck() async {
    if (_mapboxMap == null) return;

    try {
      // Enable location component
      final locationComponentSettings = _mapboxMap!.location;

      await locationComponentSettings.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: Colors.blue.value,
          pulsingMaxRadius: 30.0,
          showAccuracyRing: true,
          accuracyRingColor: Colors.blue.withOpacity(0.2).value,
          accuracyRingBorderColor: Colors.blue.withOpacity(0.4).value,
        ),
      );
    } catch (e) {
      print('Error enabling location puck: $e');
    }
  }

  Future<void> _addTaskMarker() async {
    if (_mapboxMap == null) return;

    try {
      final pointAnnotationManager = await _mapboxMap!.annotations
          .createPointAnnotationManager();

      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(widget.longitude, widget.latitude),
        ),
        iconSize: 1.5,
        iconColor: DarkThemeColors.primary100.value,
      );

      await pointAnnotationManager.create(options);
    } catch (e) {
      print('Error adding task marker: $e');
    }
  }

  void _openInMaps() async {
    // Open in default maps app
    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
    // You can use url_launcher package to open this
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Map URL: $url'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // Copy to clipboard functionality
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkThemeColors.background,
      body: Stack(
        children: [
          // Map
          MapWidget(
            key: const ValueKey('mapWidget'),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(widget.longitude, widget.latitude),
              ),
              zoom: 14.0,
            ),
            styleUri: MapboxStyles.DARK,
            onMapCreated: _onMapCreated,
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.taskTitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.locationName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DarkThemeColors.surface,
                    DarkThemeColors.surface.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DarkThemeColors.primary100.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: DarkThemeColors.primary100.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DarkThemeColors.primary100,
                              DarkThemeColors.primary100.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: DarkThemeColors.primary100.withOpacity(
                                0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.locationName,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: DarkThemeColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.pin_drop,
                                  size: 14,
                                  color: DarkThemeColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: DarkThemeColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_distance != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DarkThemeColors.primary100.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DarkThemeColors.primary100.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: DarkThemeColors.primary100.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.navigation,
                              size: 18,
                              color: DarkThemeColors.primary100,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Distance: ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                          Text(
                            _distance!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: DarkThemeColors.primary100,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' away',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: DarkThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.directions, size: 20),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DarkThemeColors.primary100,
                            side: BorderSide(
                              color: DarkThemeColors.primary100,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Share location functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Location shared!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DarkThemeColors.primary100,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                            shadowColor: DarkThemeColors.primary100.withOpacity(
                              0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 280,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DarkThemeColors.primary100.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  // If we don't yet have a current location, try to fetch it.
                  if (_currentLatitude == null || _currentLongitude == null) {
                    await _getCurrentLocation();

                    if (_currentLatitude == null || _currentLongitude == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Unable to get current location. Please enable GPS and location permissions.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                  }

                  if (_mapboxMap != null) {
                    await _mapboxMap!.setCamera(
                      CameraOptions(
                        center: Point(
                          coordinates: Position(
                            _currentLongitude!,
                            _currentLatitude!,
                          ),
                        ),
                        zoom: 14.0,
                      ),
                    );
                  }
                },
                backgroundColor: Colors.white,
                elevation: 0,
                child: Icon(
                  Icons.my_location,
                  color: DarkThemeColors.primary100,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
