import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import '../../widgets/step_tile.dart';

// FIX: Add this import so the app knows what StepDetailScreen is
import 'package:mobile_frontend/screens/step_detail/step_detail_screen.dart';

class JobStepsScreen extends ConsumerWidget {
  final JobWorkflow job;
  final bool isEmbedded;

  const JobStepsScreen({super.key, required this.job, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;

    // 1. Get Role
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.role == 'ADMIN';

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
              title: Text("Job #${job.jobId} Steps"),
              leading: BackButton(onPressed: () => context.pop()),
              actions: const [
                // FIX: Pass White color
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: AppBranding(
                    color: Colors.white,
                    size: 24,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: job.steps.length,
        itemBuilder: (context, index) {
          final step = job.steps[index];
          final isLast = index == job.steps.length - 1;

          return StepTile(
            step: step,
            isLast: isLast,
            currentWorkerId: currentWorkerId,
            onTap: () {
              // 2. RBAC Check: Is User Allowed?
              final isAssigned = step.isAssignedTo(currentWorkerId);

              if (isAdmin || isAssigned) {
                // Allowed -> Navigate
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StepDetailScreen(step: step),
                  ),
                );
              } else {
                // Denied -> Show Message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("You are not assigned to this step."),
                    backgroundColor: Colors.red.shade700,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
