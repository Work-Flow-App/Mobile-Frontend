import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/gestures.dart'; 
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

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
  }

  // NEW: Function to open the map in full screen
  void _openFullScreenMap(BuildContext context, Set<Marker> markers) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenMapScreen(markers: markers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(mapMarkersProvider);

    return Container(
      height: 400,
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
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateCameraBounds(markers),
            );

            // NEW: Use a Stack to overlay the expand button
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 2,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled:
                      true, // NEW: Enables native map intent buttons
                  zoomControlsEnabled: true, // NEW: Allows zooming buttons
                  // NEW: Steals gestures from the parent SingleChildScrollView so you can actually pan the map
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
                // NEW: Full Screen Button Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: "expand_map_btn",
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    onPressed: () => _openFullScreenMap(context, markers),
                    child: const Icon(Icons.fullscreen),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- NEW: Full Screen Map Screen ---
class FullScreenMapScreen extends StatefulWidget {
  final Set<Marker> markers;

  const FullScreenMapScreen({super.key, required this.markers});

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateCameraBounds(widget.markers);
  }

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

    // Minor delay ensures the layout is rendered before animating camera bounds
    Future.delayed(const Duration(milliseconds: 200), () {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        markers: widget.markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapToolbarEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}
