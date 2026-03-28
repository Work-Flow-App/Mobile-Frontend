import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:url_launcher/url_launcher.dart';

class StepInfoSection extends ConsumerWidget {
  final JobData jobData;
  final bool canEdit;
  final bool isLoading;

  const StepInfoSection({
    super.key,
    required this.jobData,
    required this.canEdit,
    required this.isLoading,
  });

  // Helper method to launch maps
  Future<void> _openMaps(BuildContext context, JobAddress address) async {
    final lat = address.latitude;
    final lng = address.longitude;
    final query = Uri.encodeComponent(address.fullAddress);

    Uri nativeUrl;
    Uri fallbackUrl;

    if (Platform.isIOS) {
      if (lat != null && lng != null) {
        nativeUrl = Uri.parse('https://maps.apple.com/?ll=$lat,$lng&q=$query');
      } else {
        nativeUrl = Uri.parse('https://maps.apple.com/?q=$query');
      }
    } else {
      if (lat != null && lng != null) {
        nativeUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($query)');
      } else {
        nativeUrl = Uri.parse('geo:0,0?q=$query');
      }
    }

    fallbackUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${lat != null && lng != null ? "$lat,$lng" : query}',
    );

    try {
      if (await canLaunchUrl(nativeUrl)) {
        await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open maps application.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening map: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = jobData.step;
    final customer = jobData.customer;
    final jobAddress = jobData.jobAddress;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: AnimatedOpacity(
          opacity: isLoading ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, step),
                const SizedBox(height: 32),

                // --- ACCORDION SECTIONS ---
                if (step.description.isNotEmpty)
                  _ModernAccordion(
                    title: "Task Details",
                    icon: Icons.description_outlined,
                    accentColor: Colors.indigo.shade400,
                    bgColor: Colors.indigo.shade50,
                    initiallyExpanded: true,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        step.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Colors.blueGrey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                if (jobAddress != null)
                  _ModernAccordion(
                    title: "Service Location",
                    icon: Icons.location_on_rounded,
                    accentColor: Colors.red.shade400,
                    bgColor: Colors.red.shade50,
                    initiallyExpanded: true,
                    child: _buildLocationContent(context, jobAddress),
                  ),

                if (customer != null)
                  _ModernAccordion(
                    title: "Customer Details",
                    icon: Icons.person_rounded,
                    accentColor: Colors.blue.shade400,
                    bgColor: Colors.blue.shade50,
                    child: _buildCustomerContent(customer),
                  ),

                if (jobData.assignedAssets.isNotEmpty)
                  _ModernAccordion(
                    title: "Assigned Assets",
                    icon: Icons.inventory_2_rounded,
                    accentColor: Colors.orange.shade400,
                    bgColor: Colors.orange.shade50,
                    child: _buildAssetsList(jobData.assignedAssets),
                  ),

                const SizedBox(height: 24),
                if (!canEdit) _buildReadOnlyBadge(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Widget Builders
  // ============================================================================

  Widget _buildHeader(BuildContext context, JobStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Text(
                "JOB #${jobData.jobRef}  •  STEP #${step.orderIndex}",
                style: TextStyle(
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildStatusBadge(step),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          step.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(JobStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: step.status.backgroundColor ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (step.status.color ?? Colors.blue).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.status.color ?? Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            step.status.label.toUpperCase(),
            style: TextStyle(
              color: step.status.color ?? Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context, JobAddress jobAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          jobAddress.fullAddress,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openMaps(context, jobAddress),
            icon: const Icon(Icons.directions_outlined),
            label: const Text("Get Directions"),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (jobAddress.additionalInfo?.isNotEmpty == true) ...[
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
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  jobAddress.additionalInfo!,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerContent(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildContactRow(
          Icons.phone_rounded,
          customer.telephone.isNotEmpty ? customer.telephone : customer.mobile,
          isSelectable: true,
        ),
        if (customer.email.isNotEmpty)
          _buildContactRow(
            Icons.email_rounded,
            customer.email,
            isSelectable: true,
          ),
        if (customer.address.fullAddress.isNotEmpty)
          _buildContactRow(Icons.map_rounded, customer.address.fullAddress),
      ],
    );
  }

  Widget _buildAssetsList(List<AssignedAsset> assets) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          asset.assetName?.isNotEmpty == true
                              ? asset.assetName!
                              : "Asset ID: ${asset.assetId}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getAssetStatusColor(asset.status),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              asset.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (asset.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  asset.description!,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (asset.serialNumber?.isNotEmpty == true)
                    _buildAssetChip("S/N: ${asset.serialNumber}", Icons.tag),
                  if (asset.assetTag?.isNotEmpty == true)
                    _buildAssetChip("Tag: ${asset.assetTag}", Icons.qr_code),
                ],
              ),
              if (asset.notes?.isNotEmpty == true) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        asset.notes!,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String text, {
    bool isSelectable = false,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: isSelectable
                ? SelectableText(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "View Only (Not Assigned)",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAssetStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green.shade500;
      case 'INACTIVE':
        return Colors.red.shade400;
      case 'MAINTENANCE':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade400;
    }
  }
}

// ============================================================================
// Helper UI Components (Accordion Edition)
// ============================================================================

class _ModernAccordion extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Widget child;
  final bool initiallyExpanded;

  const _ModernAccordion({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left-Edge Accent Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: accentColor),
          ),

          Theme(
            data: Theme.of(context).copyWith(
              dividerColor:
                  Colors.transparent, // Removes internal ExpansionTile borders
              splashColor: bgColor.withOpacity(0.5),
              highlightColor: bgColor.withOpacity(0.3),
            ),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              iconColor: accentColor,
              collapsedIconColor: Colors.grey.shade400,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 24,
              ),
              leading: _IconBox(
                icon: icon,
                color: accentColor,
                bgColor: bgColor,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.3,
                ),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Divider(height: 1),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _IconBox({
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor.withOpacity(0.8), bgColor],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
