import 'package:flutter/material.dart';
import 'timeline_model.dart';

// --- Job Enums & Extensions ---

enum JobStatus { NOT_STARTED, ONGOING, COMPLETED, PENDING }

extension JobStatusExtension on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.NOT_STARTED:
        return 'Not Started';
      case JobStatus.ONGOING:
        return 'Ongoing';
      case JobStatus.COMPLETED:
        return 'Completed';
      case JobStatus.PENDING:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.ONGOING:
        return Colors.blue.shade700;
      case JobStatus.COMPLETED:
        return Colors.green.shade700;
      case JobStatus.PENDING:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case JobStatus.ONGOING:
        return Colors.blue.withOpacity(0.15);
      case JobStatus.COMPLETED:
        return Colors.green.withOpacity(0.15);
      case JobStatus.PENDING:
        return Colors.red.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }
}

// --- Step Enums & Extensions ---

// 1. Added PENDING to StepStatus
enum StepStatus { NOT_STARTED, STARTED, COMPLETED, PENDING }

// 2. Created Extension for Step Styling
extension StepStatusExtension on StepStatus {
  Color get color {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.shade700;
      case StepStatus.STARTED:
        return Colors.blue.shade700;
      case StepStatus.PENDING:
        return Colors.red.shade700; // Urgent Red
      default:
        return Colors.black;
    }
  }

  Color get indicatorColor {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.shade700;
      case StepStatus.STARTED:
        return Colors.blue.shade700;
      case StepStatus.PENDING:
        return Colors.red.shade700;
      default:
        return Colors.white;
    }
  }

  Color get indicatorTextColor {
    return (this == StepStatus.NOT_STARTED) ? Colors.black : Colors.white;
  }
}

class JobWorkflow {
  final int id;
  final int jobId;
  final JobStatus status;
  final List<JobStep> steps;

  JobWorkflow({
    required this.id,
    required this.jobId,
    required this.status,
    required this.steps,
  });

  double get progress {
    if (steps.isEmpty) return 0.0;
    int completed = steps.where((s) => s.status == StepStatus.COMPLETED).length;
    return completed / steps.length;
  }

  String get currentStepName {
    // Priority logic: Pending > Started > Not Started
    final activeStep = steps.firstWhere(
      (s) => s.status == StepStatus.PENDING,
      orElse: () => steps.firstWhere(
        (s) => s.status == StepStatus.STARTED,
        orElse: () => steps.firstWhere(
          (s) => s.status == StepStatus.NOT_STARTED,
          orElse: () => steps.last,
        ),
      ),
    );
    return activeStep.name;
  }
}

class JobStep {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  final StepStatus status;
  final List<int> assignedWorkerIds;
  final List<TimelineEvent> mockTimelineEvents;

  JobStep({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.status,
    required this.assignedWorkerIds,
    this.mockTimelineEvents = const [],
  });

  bool isAssignedTo(int workerId) => assignedWorkerIds.contains(workerId);
}
