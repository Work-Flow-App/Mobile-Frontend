import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart'; // For Status Extension
import 'package:mobile_frontend/screens/step_detail/step_detail_controller.dart';

class StepInfoSection extends ConsumerWidget {
  final JobStep step;
  final bool canEdit;
  final bool isLoading;

  const StepInfoSection({
    super.key,
    required this.step,
    required this.canEdit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(stepDetailControllerProvider(step).notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            step.name,
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),

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
          const SizedBox(height: 20),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),

          // Actions
          if (canEdit) ...[
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (step.status == StepStatus.NOT_STARTED)
              _buildActionButton(
                context: context,
                label: "Start Step",
                icon: Icons.play_arrow,
                color: Colors.blue.shade700,
                onPressed: () => _handleAction(context, controller.startStep),
              )
            else if (step.status == StepStatus.STARTED)
              _buildActionButton(
                context: context,
                label: "Mark as Completed",
                icon: Icons.check,
                color: Colors.green.shade700,
                onPressed: () =>
                    _handleAction(context, controller.completeStep),
              ),
          ] else ...[
            _buildReadOnlyBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
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

  Future<void> _handleAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
