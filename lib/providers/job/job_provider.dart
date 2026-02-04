import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/services/job/job_service.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';

// Inject Dio into JobService
final jobServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return JobService(dio);
});

final jobsFutureProvider = FutureProvider<List<JobWorkflow>>((ref) async {
  // Fetch from Real API
  return ref.watch(jobServiceProvider).getJobs();
});

// Provider to fetch timeline for a specific step
final stepTimelineProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  stepId,
) async {
  return ref.watch(jobServiceProvider).getStepTimeline(stepId);
});

final jobStatusFilterProvider = StateProvider<JobStatus?>((ref) => null);

final filteredJobsProvider = Provider<List<JobWorkflow>>((ref) {
  final jobsAsync = ref.watch(jobsFutureProvider);
  final filter = ref.watch(jobStatusFilterProvider);
  return jobsAsync.when(
    data: (jobs) =>
        filter == null ? jobs : jobs.where((j) => j.status == filter).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final selectedJobIdProvider = StateProvider<int?>((ref) => null);
