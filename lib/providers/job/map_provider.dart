import 'dart:io' show Platform; // NEW: Required for Platform check
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

// 1. Manages a Set of statuses for multi-selection. If empty, all are shown.
final mapStatusFilterProvider = StateProvider<Set<StepStatus>>((ref) => {});

// --- UPDATED: Platform-aware directions launcher ---
Future<void> _launchDirections(
  double lat,
  double lng,
  String? addressInfo,
) async {
  Uri nativeUrl;

  // A more reliable fallback URL for Google Maps in the browser
  Uri fallbackUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );

  // If we have an address string, we can pass it as the query for better routing
  final query = addressInfo != null && addressInfo.isNotEmpty
      ? Uri.encodeComponent(addressInfo)
      : '$lat,$lng';

  if (Platform.isIOS) {
    // Launch Apple Maps natively
    nativeUrl = Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$query');
  } else {
    // Launch default Android map app (usually Google Maps)
    nativeUrl = Uri.parse('geo:$lat,$lng?q=$query');
  }

  try {
    if (await canLaunchUrl(nativeUrl)) {
      await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUrl)) {
      // Fallback to browser if native app isn't installed
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch any map application.");
    }
  } catch (e) {
    debugPrint("Error launching map: $e");
  }
}

// 2. Generates the markers based on assigned steps and active filters.
final mapMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  final jobsAsync = ref.watch(assignedStepsFutureProvider);
  final activeFilters = ref.watch(mapStatusFilterProvider);

  final Set<Marker> markers = {};

  if (jobsAsync.value == null) return markers;

  final filteredJobs = jobsAsync.value!.where((job) {
    if (activeFilters.isEmpty) return true;
    return activeFilters.contains(job.step.status);
  }).toList();

  for (var job in filteredJobs) {
    if (job.jobAddress == null) continue;

    LatLng? position;

    try {
      if (job.jobAddress!.fullAddress.isNotEmpty) {
        List<geo.Location> locations = await geo.locationFromAddress(
          job.jobAddress!.fullAddress,
        );
        if (locations.isNotEmpty) {
          position = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
        }
      }
    } catch (e) {
      debugPrint("Geocoding failed, falling back to exact coords.");
    }

    if (position == null &&
        job.jobAddress!.latitude != null &&
        job.jobAddress!.longitude != null) {
      position = LatLng(job.jobAddress!.latitude!, job.jobAddress!.longitude!);
    }

    if (position != null) {
      final hue = _colorToHue(job.step.status.color);
      final finalPosition = position;
      final addressString =
          job.jobAddress!.fullAddress; // Grab address for query

      markers.add(
        Marker(
          markerId: MarkerId(job.jobId.toString()),
          position: finalPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: job.step.name,
            snippet:
                '${job.customer?.name ?? "No Customer"} • Tap for directions',
            // UPDATED: Pass address string if available
            onTap: () => _launchDirections(
              finalPosition.latitude,
              finalPosition.longitude,
              addressString,
            ),
          ),
        ),
      );
    }
  }

  return markers;
});

double _colorToHue(Color color) {
  HSLColor hsl = HSLColor.fromColor(color);
  return hsl.hue;
}
