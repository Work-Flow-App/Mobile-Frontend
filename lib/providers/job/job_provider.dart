import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/services/job/job_service.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';

// Inject Dio into JobService
final jobServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return JobService(dio);
});

final assignedStepsFutureProvider = FutureProvider<List<JobStep>>((ref) async {
  return ref.watch(jobServiceProvider).getAssignedSteps();
});

// Provider to fetch timeline for a specific step
final stepTimelineProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  stepId,
) async {
  return ref.watch(jobServiceProvider).getStepTimeline(stepId);
});

final stepStatusFilterProvider = StateProvider<StepStatus?>((ref) => null);

final filteredStepsProvider = Provider<List<JobStep>>((ref) {
  final stepsAsync = ref.watch(assignedStepsFutureProvider);
  final filter = ref.watch(stepStatusFilterProvider);

  return stepsAsync.when(
    data: (steps) => filter == null
        ? steps
        : steps.where((s) => s.status == filter).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Used for Tablet view selection
final selectedStepIdProvider = StateProvider<int?>((ref) => null);
