import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_frontend/models/asset/asset_model.dart';
import 'package:mobile_frontend/providers/asset/asset_provider.dart';
import 'package:intl/intl.dart';

class AssetCard extends ConsumerStatefulWidget {
  final AssetAssignment asset;
  final bool isGrid; // <-- RESTORED FLAG

  const AssetCard({
    super.key,
    required this.asset,
    this.isGrid = false, // <-- RESTORED DEFAULT VALUE
  });

  @override
  ConsumerState<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends ConsumerState<AssetCard> {
  bool _isLocating = false;

  Future<void> _fetchAndReviewLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions denied");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw Exception("Could not resolve address from coordinates.");
      }

      Placemark place = placemarks.first;

      if (mounted) setState(() => _isLocating = false);

      if (mounted) {
        _showReviewSheet(place, position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch location: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReviewSheet(Placemark place, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LocationReviewSheet(
          initialPlace: place,
          latitude: lat,
          longitude: lng,
          onConfirm: (payload) async {
            try {
              await ref
                  .read(assetLocationUpdaterProvider.notifier)
                  .updateLocation(widget.asset.assignmentId, payload);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Location updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Update failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;

    // --- 1. EXTRACT HEADER CONTENT ---
    final Widget headerContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: asset.statusColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: asset.statusColor.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: asset.statusColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              asset.assetName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );

    // --- 2. EXTRACT BODY CONTENT ---
    final Widget bodyContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (asset.description.isNotEmpty) ...[
            Text(
              asset.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip("S/N: ${asset.serialNumber}", Icons.numbers),
              _buildChip("Tag: ${asset.assetTag}", Icons.qr_code_2),
            ],
          ),

          // --- ASSET SLA TRACKER ---
          if (asset.assignedAt != null || asset.durationDays != null)
            _buildAssetSlaTracker(asset),

          // --- NOTES SECTION ---
          if (asset.notes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    asset.notes,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

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

          // --- FETCH LOCATION BUTTON ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLocating ? null : _fetchAndReviewLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                _isLocating
                    ? "Fetching Location..."
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
    );

    // --- 3. FINAL LAYOUT COMBINATION ---
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
          mainAxisSize: MainAxisSize.min, // Crucial for standard ListView
          children: [
            headerContent,

            // --- SCROLL PROTECTION ---
            // If inside a grid, make the body scrollable to prevent overflow!
            if (widget.isGrid)
              Expanded(child: SingleChildScrollView(child: bodyContent))
            else
              bodyContent,
          ],
        ),
      ),
    );
  }

  Widget _buildAssetSlaTracker(AssetAssignment asset) {
    final assignedDate = asset.assignedAt;

    final int currentDays =
        asset.durationDays ??
        (assignedDate != null
            ? DateTime.now().difference(assignedDate).inDays
            : 0);

    final int? limitDays = asset.expectedDurationDays;

    bool isBreached =
        asset.slaBreached || (limitDays != null && currentDays > limitDays);

    if (asset.notes.contains('SLA Breached!')) {
      isBreached = true;
    }

    final Color statusColor = isBreached
        ? Colors.red.shade600
        : Colors.teal.shade600;
    final Color bgColor = isBreached ? Colors.red.shade50 : Colors.teal.shade50;
    final IconData statusIcon = isBreached
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Text(
                "Asset SLA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBreached ? "BREACHED" : "ON TRACK",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildSlaStatInfo(
                "Checked Out",
                assignedDate != null
                    ? DateFormat('MMM dd, yyyy').format(assignedDate)
                    : "Unknown",
                Icons.calendar_today_outlined,
                statusColor,
              ),
              _buildSlaStatInfo(
                "Duration",
                "$currentDays Days",
                Icons.timer_outlined,
                statusColor,
              ),
              if (limitDays != null)
                _buildSlaStatInfo(
                  "SLA Limit",
                  "$limitDays Days",
                  Icons.flag_outlined,
                  statusColor,
                ),
            ],
          ),
          if (limitDays != null && limitDays > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (currentDays / limitDays).clamp(0.0, 1.0),
                backgroundColor: statusColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlaStatInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
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

// =========================================================================
// WIDGET: Modern Location Review Sheet
// =========================================================================
class _LocationReviewSheet extends StatefulWidget {
  final Placemark initialPlace;
  final double latitude;
  final double longitude;
  final Future<void> Function(Map<String, dynamic>) onConfirm;

  const _LocationReviewSheet({
    required this.initialPlace,
    required this.latitude,
    required this.longitude,
    required this.onConfirm,
  });

  @override
  State<_LocationReviewSheet> createState() => _LocationReviewSheetState();
}

class _LocationReviewSheetState extends State<_LocationReviewSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _zipCtrl;
  late TextEditingController _countryCtrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final place = widget.initialPlace;
    String streetName = place.street ?? place.name ?? "";
    if (streetName.isEmpty && place.thoroughfare != null) {
      streetName = "${place.subThoroughfare ?? ''} ${place.thoroughfare}"
          .trim();
    }

    _streetCtrl = TextEditingController(text: streetName);
    _cityCtrl = TextEditingController(
      text: place.locality ?? place.subAdministrativeArea ?? "",
    );
    _stateCtrl = TextEditingController(text: place.administrativeArea ?? "");
    _zipCtrl = TextEditingController(text: place.postalCode ?? "");
    _countryCtrl = TextEditingController(text: place.country ?? "");
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      "street": _streetCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "state": _stateCtrl.text.trim(),
      "postalCode": _zipCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),
      "latitude": widget.latitude,
      "longitude": widget.longitude,
    };

    await widget.onConfirm(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Review Address",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Please confirm or edit the location details before saving.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: "Street Address",
                          controller: _streetCtrl,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: "City",
                                controller: _cityCtrl,
                                isRequired: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: "State/Region",
                                controller: _stateCtrl,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: "Postal Code",
                                controller: _zipCtrl,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: "Country",
                                controller: _countryCtrl,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Confirm & Save",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_isSubmitting,
          validator: isRequired
              ? (val) => (val == null || val.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
