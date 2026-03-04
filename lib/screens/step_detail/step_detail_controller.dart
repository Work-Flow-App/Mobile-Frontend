import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

// 1. State class to hold loading status and current step data
class StepDetailState {
  final bool isLoading;
  final JobStep step;

  StepDetailState({required this.isLoading, required this.step});

  StepDetailState copyWith({bool? isLoading, JobStep? step}) {
    return StepDetailState(
      isLoading: isLoading ?? this.isLoading,
      step: step ?? this.step,
    );
  }
}

// 2. Controller to handle actions
class StepDetailController extends StateNotifier<StepDetailState> {
  final Ref ref;

  StepDetailController(this.ref, JobStep initialStep)
    : super(StepDetailState(isLoading: false, step: initialStep));

  Future<void> refreshTimeline() {
    return ref.refresh(stepTimelineProvider(state.step.id).future);
  }

  // NEW: Added a dedicated method to refresh all step data
  Future<void> refreshStepData() async {
    state = state.copyWith(isLoading: true);
    try {
      await refreshTimeline();
      // Refresh parent provider to fetch updated step statuses
      ref.refresh(assignedStepsFutureProvider);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> startStep() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(jobServiceProvider).startStep(state.step.id);

      // Optimistic update
      final updatedStep = JobStep(
        id: state.step.id,
        name: state.step.name,
        description: state.step.description,
        orderIndex: state.step.orderIndex,
        status: StepStatus.STARTED,
        assignedWorkerIds: state.step.assignedWorkerIds,
      );

      state = state.copyWith(isLoading: false, step: updatedStep);
      refreshTimeline();
      ref.refresh(assignedStepsFutureProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow; // Let UI handle error display
    }
  }

  Future<void> completeStep() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(jobServiceProvider).completeStep(state.step.id);

      final updatedStep = JobStep(
        id: state.step.id,
        name: state.step.name,
        description: state.step.description,
        orderIndex: state.step.orderIndex,
        status: StepStatus.COMPLETED,
        assignedWorkerIds: state.step.assignedWorkerIds,
      );

      state = state.copyWith(isLoading: false, step: updatedStep);
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
          .addComment(state.step.id, text.trim(), type);
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
          .addAttachment(state.step.id, path, type, description);
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
    .autoDispose<StepDetailController, StepDetailState, JobStep>((ref, step) {
      return StepDetailController(ref, step);
    });
