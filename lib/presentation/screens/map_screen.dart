import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName ?? 'Location'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: MapWidget(
        key: ValueKey("mapWidget"),
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(widget.longitude, widget.latitude),
          ),
          zoom: 15.0,
        ),
        onMapCreated: _onMapCreated,
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Add a marker at the location
    await _addMarker();
  }

  Future<void> _addMarker() async {
    if (_mapboxMap == null) return;

    try {
      // Create point annotation manager
      final pointAnnotationManager = await _mapboxMap!.annotations
          .createPointAnnotationManager();

      // Create point annotation options
      final pointAnnotationOptions = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(widget.longitude, widget.latitude),
        ),
        iconSize: 1.5,
        iconColor: Colors.red.value,
      );

      // Add the annotation
      await pointAnnotationManager.create(pointAnnotationOptions);
    } catch (e) {
      print('Error adding marker: $e');
    }
  }
}
