import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

// 1. State class to hold loading status and current step data
class StepDetailState {
  final bool isLoading;
  final JobData jobData; // Updated

  StepDetailState({required this.isLoading, required this.jobData});

  StepDetailState copyWith({bool? isLoading, JobData? jobData}) {
    return StepDetailState(
      isLoading: isLoading ?? this.isLoading,
      jobData: jobData ?? this.jobData,
    );
  }
}

// 2. Controller to handle actions
class StepDetailController extends StateNotifier<StepDetailState> {
  final Ref ref;

  StepDetailController(this.ref, JobData initialData)
    : super(StepDetailState(isLoading: false, jobData: initialData));

  Future<void> refreshTimeline() {
    return ref.refresh(stepTimelineProvider(state.jobData.step.id).future);
  }

  Future<void> refreshWorkLogs() {
    return ref.refresh(stepWorkLogsProvider(state.jobData.step.id).future);
  }

  Future<void> refreshStepData() async {
    state = state.copyWith(isLoading: true);
    try {
      await refreshTimeline();
      await refreshWorkLogs();
      ref.refresh(assignedStepsFutureProvider);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addWorkLog({
    required String visitDate,
    required String timeIn,
    required String timeOut,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(jobServiceProvider)
          .addWorkLog(
            stepId: state.jobData.step.id,
            visitDate: visitDate,
            timeIn: timeIn,
            timeOut: timeOut,
            description: description,
          );
      await refreshWorkLogs();
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startStep() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(jobServiceProvider).startStep(state.jobData.step.id);

      final updatedStep = JobStep(
        id: state.jobData.step.id,
        name: state.jobData.step.name,
        description: state.jobData.step.description,
        orderIndex: state.jobData.step.orderIndex,
        status: StepStatus.STARTED,
        assignedWorkerIds: state.jobData.step.assignedWorkerIds,
      );

      // Recreate the wrapper
      final updatedJobData = JobData(
        step: updatedStep,
        jobId: state.jobData.jobId,
        customer: state.jobData.customer,
        assignedAssets: state.jobData.assignedAssets,
        jobAddress: state.jobData.jobAddress,
      );

      state = state.copyWith(isLoading: false, jobData: updatedJobData);
      refreshTimeline();
      ref.refresh(assignedStepsFutureProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> completeStep() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(jobServiceProvider).completeStep(state.jobData.step.id);

      final updatedStep = JobStep(
        id: state.jobData.step.id,
        name: state.jobData.step.name,
        description: state.jobData.step.description,
        orderIndex: state.jobData.step.orderIndex,
        status: StepStatus.COMPLETED,
        assignedWorkerIds: state.jobData.step.assignedWorkerIds,
      );

      final updatedJobData = JobData(
        step: updatedStep,
        jobId: state.jobData.jobId,
        customer: state.jobData.customer,
        assignedAssets: state.jobData.assignedAssets,
        jobAddress: state.jobData.jobAddress,
      );

      state = state.copyWith(isLoading: false, jobData: updatedJobData);
      refreshTimeline();
      ref.refresh(assignedStepsFutureProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> addComment(String text, StepDiscussionType type) async {
    if (text.trim().isEmpty) return;
    try {
      await ref
          .read(jobServiceProvider)
          .addComment(state.jobData.step.id, text.trim(), type);
      refreshTimeline();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadFile(
    String path,
    StepDiscussionType type,
    String? description,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref
          .read(jobServiceProvider)
          .addAttachment(state.jobData.step.id, path, type, description);
      refreshTimeline();
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// 3. Provider Family to create a unique controller for each Step ID
final stepDetailControllerProvider = StateNotifierProvider.family
    .autoDispose<StepDetailController, StepDetailState, JobData>((
      ref,
      jobData,
    ) {
      return StepDetailController(ref, jobData);
    });
