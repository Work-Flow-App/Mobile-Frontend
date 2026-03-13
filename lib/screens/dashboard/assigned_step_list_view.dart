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
        data: (data) => RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(assignedStepsFutureProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: const Center(child: Text("No steps found.")),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // This forces Riverpod to re-fetch the data from the API
        return await ref.refresh(assignedStepsFutureProvider.future);
      },
      child: ListView.builder(
        // Add physics to ensure the list is always scrollable (needed for pull-to-refresh to work even if the list is short)
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filteredSteps.length,
        // Inside AssignedStepListView
        itemBuilder: (context, index) {
          final jobItem = filteredSteps[index]; 
          return StepCard(
            jobData: jobItem,
            isSelected: isTablet && jobItem.step.id == selectedId,
            onTap: () {
              if (isTablet) {
                ref.read(selectedStepIdProvider.notifier).state =
                    jobItem.step.id;
              } else {
                context.push(
                  '/step-detail',
                  extra: jobItem,
                ); // Send whole wrapper
              }
            },
          );
        },
      ),
    );
  }
}
