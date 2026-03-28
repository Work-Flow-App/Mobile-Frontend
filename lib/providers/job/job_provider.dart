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
    data: (jobDataList) {
      // 1. Filter the list first
      List<JobData> processedList = filter == null
          ? List<JobData>.from(jobDataList) // Create a copy so we can sort it
          : jobDataList.where((jd) => jd.step.status == filter).toList();

      // 2. Sort the list: jobRef Descending, then orderIndex Ascending
      processedList.sort((a, b) {
        // Handle null jobRefs gracefully (defaulting to 0 for comparison)
        final aRef = a.jobRef ?? 0;
        final bRef = b.jobRef ?? 0;

        // Compare jobRef Descending (b compared to a)
        int refComparison = bRef.compareTo(aRef);

        if (refComparison != 0) {
          return refComparison;
        }

        // If jobRefs are equal, compare orderIndex Ascending (a compared to b)
        return a.step.orderIndex.compareTo(b.step.orderIndex);
      });

      return processedList;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Used for Tablet view selection
final selectedStepIdProvider = StateProvider<int?>((ref) => null);
