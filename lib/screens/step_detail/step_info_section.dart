import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = jobData.step;
    final customer = jobData.customer;
    final jobAddress = jobData.jobAddress;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 850,
        ), // Slightly wider for grid
        child: AnimatedOpacity(
          opacity: isLoading ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine if screen is wide enough for a 2-column layout
                final isWideScreen = constraints.maxWidth > 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, step),
                    const SizedBox(height: 40),

                    if (step.description.isNotEmpty) ...[
                      const _SectionTitle(title: "Task Details"),
                      Text(
                        step.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: Colors.blueGrey.shade800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // --- RESPONSIVE GRID FOR LOCATION & CUSTOMER ---
                    if (isWideScreen)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (jobAddress != null)
                            Expanded(child: _buildLocationCard(jobAddress)),
                          if (jobAddress != null && customer != null)
                            const SizedBox(width: 24),
                          if (customer != null)
                            Expanded(child: _buildCustomerCard(customer)),
                        ],
                      )
                    else ...[
                      if (jobAddress != null) _buildLocationCard(jobAddress),
                      if (jobAddress != null && customer != null)
                        const SizedBox(height: 32),
                      if (customer != null) _buildCustomerCard(customer),
                    ],

                    const SizedBox(height: 40),

                    if (jobData.assignedAssets.isNotEmpty) ...[
                      const _SectionTitle(title: "Assigned Assets"),
                      _buildAssetsList(jobData.assignedAssets),
                      const SizedBox(height: 40),
                    ],

                    if (!canEdit) _buildReadOnlyBadge(),
                    const SizedBox(height: 40),
                  ],
                );
              },
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
                "JOB #${jobData.jobId}  •  STEP #${step.orderIndex}",
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
        color:
            step.status.backgroundColor ??
            Colors.blue.shade50, // Added fallback
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (step.status.color ?? Colors.blue).withOpacity(
            0.2,
          ), // Added fallback
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
              color: step.status.color ?? Colors.blue, // Added fallback
            ),
          ),
          const SizedBox(width: 8),
          Text(
            step.status.label.toUpperCase(),
            style: TextStyle(
              color: step.status.color ?? Colors.blue, // Added fallback
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(JobAddress jobAddress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Service Location"),
        _ModernCard(
          accentColor: Colors.red.shade400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(
                    icon: Icons.location_on_rounded,
                    color: Colors.red.shade600,
                    bgColor: Colors.red.shade50,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectableText(
                      jobAddress.fullAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Customer Details"),
        _ModernCard(
          accentColor: Colors.blue.shade400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconBox(
                    icon: Icons.person_rounded,
                    color: Colors.blue.shade600,
                    bgColor: Colors.blue.shade50,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectableText(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              _buildContactRow(
                Icons.phone_rounded,
                customer.telephone.isNotEmpty
                    ? customer.telephone
                    : customer.mobile,
                isSelectable: true,
              ),
              if (customer.email.isNotEmpty)
                _buildContactRow(
                  Icons.email_rounded,
                  customer.email,
                  isSelectable: true,
                ),
              if (customer.address.fullAddress.isNotEmpty)
                _buildContactRow(
                  Icons.map_rounded,
                  customer.address.fullAddress,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsList(List<AssignedAsset> assets) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return _ModernCard(
          accentColor: Colors.orange.shade400,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBox(
                    icon: Icons.inventory_2_rounded,
                    color: Colors.orange.shade600,
                    bgColor: Colors.orange.shade50,
                  ),
                  const SizedBox(width: 16),
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
                const SizedBox(height: 16),
                Text(
                  asset.description!,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
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
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Row(
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
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
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
// Helper UI Components (Premium Edition)
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.indigo.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
              fontSize: 20,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor.withOpacity(0.8), bgColor],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2), // Tinted shadow matching the icon
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  const _ModernCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final shadowColor = accentColor ?? Colors.black;

    return Container(
      clipBehavior: Clip
          .antiAlias, // Needed to keep the accent line inside the rounded corners
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.shade50.withOpacity(
              0.5,
            ), // Very subtle off-white at the bottom
          ],
        ),
        boxShadow: [
          // A softer, more spread out shadow tinted with the card's accent color
          BoxShadow(
            color: shadowColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shadowColor.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // The Left-Edge Accent Strip
          if (accentColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accentColor),
            ),

          // The Content
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
