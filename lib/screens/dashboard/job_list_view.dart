import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:mobile_frontend/providers/job/job_provider.dart';
import '../../widgets/job_card.dart';

class JobListView extends ConsumerWidget {
  final bool isTablet;
  const JobListView({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredJobs = ref.watch(filteredJobsProvider);
    final selectedId = ref.watch(selectedJobIdProvider);

    if (filteredJobs.isEmpty) {
      return const Center(child: Text("No jobs found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredJobs.length,
      itemBuilder: (context, index) {
        final job = filteredJobs[index];
        return JobCard(
          job: job,
          isSelected: isTablet && job.id == selectedId,
          onTap: () {
            if (isTablet) {
              ref.read(selectedJobIdProvider.notifier).state = job.id;
            } else {
              // GO_ROUTER IMPLEMENTATION
              context.push('/job-detail', extra: job);
            }
          },
        );
      },
    );
  }
}