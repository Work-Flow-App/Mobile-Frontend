import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/services/job/job_service.dart';

final jobServiceProvider = Provider((ref) => JobService());

final jobsFutureProvider = FutureProvider<List<JobWorkflow>>((ref) async {
  return ref.watch(jobServiceProvider).getJobs();
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
