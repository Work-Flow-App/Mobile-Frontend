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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subhead Job ID
          Text(
            "JOB #${jobData.jobId}  •  STEP #${step.orderIndex}",
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            step.name,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: step.status.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Status: ${step.status.name}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: step.status.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          if (step.description.isNotEmpty) ...[
            Text(
              "Task Details",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 32),
          ],

          // JOB ADDRESS CARD 
          if (jobAddress != null) ...[
            Text(
              "Service Location",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade50,
                        child: Icon(Icons.location_on, color: Colors.red.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          jobAddress.fullAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (jobAddress.additionalInfo != null && jobAddress.additionalInfo!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            jobAddress.additionalInfo!,
                            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // CUSTOMER INFO CARD
          if (customer != null) ...[
            Text(
              "Customer details",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.person, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _buildContactRow(
                    Icons.phone,
                    customer.telephone.isNotEmpty
                        ? customer.telephone
                        : customer.mobile,
                  ),
                  if (customer.email.isNotEmpty)
                    _buildContactRow(Icons.email, customer.email),
                  if (customer.address.fullAddress.isNotEmpty)
                    _buildContactRow(
                      Icons.location_on,
                      customer.address.fullAddress,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // ASSIGNED ASSETS
          if (jobData.assignedAssets.isNotEmpty) ...[
            Text(
              "Assigned Assets",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobData.assignedAssets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final asset = jobData.assignedAssets[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Asset ID: ${asset.assetId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Status: ${asset.status}"),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          if (!canEdit) _buildReadOnlyBadge(),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            "View Only (Not Assigned)",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
