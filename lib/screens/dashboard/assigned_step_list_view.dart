import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/step_card.dart'; // Import the new card

class AssignedStepListView extends ConsumerWidget {
  final bool isTablet;
  const AssignedStepListView({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to the new filtered steps provider
    final filteredSteps = ref.watch(filteredStepsProvider);
    final selectedId = ref.watch(selectedStepIdProvider);

    if (filteredSteps.isEmpty) {
      // Check if it's loading or actually empty
      final asyncValue = ref.watch(assignedStepsFutureProvider);
      return asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (data) => const Center(child: Text("No steps found.")),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSteps.length,
      itemBuilder: (context, index) {
        final step = filteredSteps[index];
        return StepCard(
          step: step,
          isSelected: isTablet && step.id == selectedId,
          onTap: () {
            if (isTablet) {
              ref.read(selectedStepIdProvider.notifier).state = step.id;
            } else {
              // --- DIRECT NAVIGATION TO STEP DETAIL ---
              context.push('/step-detail', extra: step);
            }
          },
        );
      },
    );
  }
}
