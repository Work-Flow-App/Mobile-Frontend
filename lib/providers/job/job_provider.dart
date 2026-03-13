import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/services/job/job_service.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';
import 'package:mobile_frontend/models/job/work_log_model.dart';

// Inject Dio into JobService
final jobServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return JobService(dio);
});

final assignedStepsFutureProvider = FutureProvider<List<JobData>>((ref) async {
  return ref.watch(jobServiceProvider).getAssignedSteps();
});

// Provider to fetch timeline for a specific step
final stepTimelineProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  stepId,
) async {
  return ref.watch(jobServiceProvider).getStepTimeline(stepId);
});

final stepWorkLogsProvider = FutureProvider.family<WorkLogResponse, int>((
  ref,
  stepId,
) async {
  return ref.watch(jobServiceProvider).getWorkLogs(stepId);
});

final stepStatusFilterProvider = StateProvider<StepStatus?>((ref) => null);

final filteredStepsProvider = Provider<List<JobData>>((ref) {
  final stepsAsync = ref.watch(assignedStepsFutureProvider);
  final filter = ref.watch(stepStatusFilterProvider);

  return stepsAsync.when(
    // Filter by looking at the nested .step.status
    data: (jobDataList) => filter == null
        ? jobDataList
        : jobDataList.where((jd) => jd.step.status == filter).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Used for Tablet view selection
final selectedStepIdProvider = StateProvider<int?>((ref) => null);
