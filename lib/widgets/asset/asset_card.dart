import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_frontend/models/asset/asset_model.dart';
import 'package:mobile_frontend/providers/asset/asset_provider.dart';
import 'package:intl/intl.dart';

class AssetCard extends ConsumerStatefulWidget {
  final AssetAssignment asset;

  const AssetCard({super.key, required this.asset});

  @override
  ConsumerState<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends ConsumerState<AssetCard> {
  bool _isLocating = false;

  Future<void> _updateToCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception("Location permissions denied");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // 2. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Reverse Geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty)
        throw Exception("Could not resolve address from coordinates.");

      Placemark place = placemarks.first;

      // 4. Build API Payload
      final locationPayload = {
        "street": place.street ?? place.name ?? "",
        "city": place.locality ?? place.subAdministrativeArea ?? "",
        "state": place.administrativeArea ?? "",
        "postalCode": place.postalCode ?? "",
        "country": place.country ?? "",
        "latitude": position.latitude,
        "longitude": position.longitude,
      };

      // 5. Call API via Provider
      await ref
          .read(assetLocationUpdaterProvider.notifier)
          .updateLocation(widget.asset.assignmentId, locationPayload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update location: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP HEADER ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: asset.statusColor.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(color: asset.statusColor.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    color: asset.statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      asset.assetName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: asset.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      asset.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BODY CONTENT ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (asset.description.isNotEmpty) ...[
                    Text(
                      asset.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Meta tags (Serial, Tag)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip("S/N: ${asset.serialNumber}", Icons.numbers),
                      _buildChip("Tag: ${asset.assetTag}", Icons.qr_code_2),
                      if (asset.assignedAt != null)
                        _buildChip(
                          "Assigned: ${DateFormat('MMM dd').format(asset.assignedAt!)}",
                          Icons.calendar_today,
                        ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),

                  // --- LOCATION SECTION ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Current Known Location",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              asset.address?.fullAddress ?? "Location not set",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: asset.address == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: asset.address == null
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- UPDATE LOCATION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLocating ? null : _updateToCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(
                        _isLocating
                            ? "Locating & Updating..."
                            : "Set to My Current Location",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
