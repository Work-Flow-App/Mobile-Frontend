import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/providers/job/map_provider.dart';

class JobLocationsMap extends ConsumerStatefulWidget {
  const JobLocationsMap({super.key});

  @override
  ConsumerState<JobLocationsMap> createState() => _JobLocationsMapState();
}

class _JobLocationsMapState extends ConsumerState<JobLocationsMap> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Calculates the boundary to zoom perfectly on all markers
  void _updateCameraBounds(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var marker in markers) {
      if (minLat == null || marker.position.latitude < minLat)
        minLat = marker.position.latitude;
      if (maxLat == null || marker.position.latitude > maxLat)
        maxLat = marker.position.latitude;
      if (minLng == null || marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (maxLng == null || marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    // Add padding so markers aren't touching the edges
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(mapMarkersProvider);

    return Container(
      height: 400, // Adaptive height can be set by parent using Constraints
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: markersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
          error: (err, stack) => Center(child: Text('Map Error: $err')),
          data: (markers) {
            // Auto-zoom to markers when data arrives
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateCameraBounds(markers),
            );

            return GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0), // Will be updated immediately by bounds
                zoom: 2,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false, // Cleaner UI
            );
          },
        ),
      ),
    );
  }
}
