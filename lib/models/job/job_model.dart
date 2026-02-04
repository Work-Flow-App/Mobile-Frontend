import 'package:flutter/material.dart';
import 'timeline_model.dart';

// --- Job Enums & Extensions ---

enum JobStatus { NOT_STARTED, STARTED, ONGOING, COMPLETED, PENDING }

extension JobStatusExtension on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.NOT_STARTED:
        return 'Not Started';
      case JobStatus.STARTED:
        return 'Started';
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
      case JobStatus.STARTED:
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
      case JobStatus.STARTED:
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

enum StepStatus { NOT_STARTED, STARTED, COMPLETED, PENDING }

extension StepStatusExtension on StepStatus {
  Color get color {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.shade700;
      case StepStatus.STARTED:
        return Colors.blue.shade700;
      case StepStatus.PENDING:
        return Colors.red.shade700;
      default:
        return Colors.black;
    }
  }

  // --- FIX: Added backgroundColor here ---
  Color get backgroundColor {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.withOpacity(0.15);
      case StepStatus.STARTED:
        return Colors.blue.withOpacity(0.15);
      case StepStatus.PENDING:
        return Colors.red.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
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

  factory JobWorkflow.fromJson(Map<String, dynamic> json) {
    var stepList = json['steps'] as List;
    // Map API status string to Enum safely
    JobStatus mappedStatus = JobStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => JobStatus.NOT_STARTED,
    );

    return JobWorkflow(
      id: json['id'],
      jobId: json['jobId'],
      status: mappedStatus,
      steps: stepList.map((i) => JobStep.fromJson(i)).toList(),
    );
  }

  double get progress {
    if (steps.isEmpty) return 0.0;
    int completed = steps.where((s) => s.status == StepStatus.COMPLETED).length;
    return completed / steps.length;
  }

  String get currentStepName {
    if (steps.isEmpty) return "No steps";
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
  List<TimelineEvent> mockTimelineEvents;

  JobStep({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.status,
    required this.assignedWorkerIds,
    this.mockTimelineEvents = const [],
  });

  factory JobStep.fromJson(Map<String, dynamic> json) {
    StepStatus mappedStatus = StepStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => StepStatus.NOT_STARTED,
    );

    return JobStep(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? "",
      orderIndex: json['orderIndex'],
      status: mappedStatus,
      assignedWorkerIds: List<int>.from(json['assignedWorkerIds'] ?? []),
    );
  }

  bool isAssignedTo(int workerId) => assignedWorkerIds.contains(workerId);
}
