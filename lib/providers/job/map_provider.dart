import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

// 1. Manages a Set of statuses for multi-selection. If empty, all are shown.
final mapStatusFilterProvider = StateProvider<Set<StepStatus>>((ref) => {});

// 2. Generates the markers based on assigned steps and active filters.
final mapMarkersProvider = FutureProvider<Set<Marker>>((ref) async {
  final jobsAsync = ref.watch(assignedStepsFutureProvider);
  final activeFilters = ref.watch(mapStatusFilterProvider);

  final Set<Marker> markers = {};

  if (jobsAsync.value == null) return markers;

  // Filter jobs based on the selected statuses
  final filteredJobs = jobsAsync.value!.where((job) {
    if (activeFilters.isEmpty) return true; // Show all if no filter
    return activeFilters.contains(job.step.status);
  }).toList();

  for (var job in filteredJobs) {
    if (job.jobAddress == null) continue;

    LatLng? position;

    // First attempt: Geocode the address string (as requested)
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
      debugPrint(
        "Geocoding failed for ${job.jobAddress!.fullAddress}, falling back to exact coords.",
      );
    }

    // Fallback attempt: Use the database latitude/longitude
    if (position == null &&
        job.jobAddress!.latitude != null &&
        job.jobAddress!.longitude != null) {
      position = LatLng(job.jobAddress!.latitude!, job.jobAddress!.longitude!);
    }

    if (position != null) {
      // Create a marker with a hue matching the status color
      final hue = _colorToHue(job.step.status.color);

      markers.add(
        Marker(
          markerId: MarkerId(job.jobId.toString()),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: job.step.name,
            snippet:
                '${job.customer?.name ?? "No Customer"} • ${job.step.status.label}',
          ),
        ),
      );
    }
  }

  return markers;
});

// Helper to convert your StepStatus colors to Google Maps Hue
double _colorToHue(Color color) {
  HSLColor hsl = HSLColor.fromColor(color);
  return hsl.hue;
}
