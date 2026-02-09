import 'package:flutter/material.dart';
import 'timeline_model.dart';

// --- Step Enums & Extensions ---

// Updated to match Java: INITIATED, NOT_STARTED, PENDING, ONGOING, STARTED, COMPLETED, SKIPPED
enum StepStatus {
  INITIATED,
  NOT_STARTED,
  PENDING,
  ONGOING,
  STARTED,
  COMPLETED,
  SKIPPED,
}

extension StepStatusExtension on StepStatus {
  String get label {
    // Human readable labels
    return name.replaceAll('_', ' ');
  }

  Color get color {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.shade700;
      case StepStatus.STARTED:
      case StepStatus.ONGOING:
        return Colors.blue.shade700;
      case StepStatus.PENDING:
        return Colors.red.shade700;
      case StepStatus.SKIPPED:
        return Colors.amber.shade800;
      case StepStatus.INITIATED:
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case StepStatus.COMPLETED:
        return Colors.green.withOpacity(0.15);
      case StepStatus.STARTED:
      case StepStatus.ONGOING:
        return Colors.blue.withOpacity(0.15);
      case StepStatus.PENDING:
        return Colors.red.withOpacity(0.15);
      case StepStatus.SKIPPED:
        return Colors.amber.withOpacity(0.15);
      case StepStatus.INITIATED:
        return Colors.purple.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }
}

class JobStep {
  final int id;
  final String name;
  final String description;
  final int orderIndex;
  final StepStatus status;
  final List<int> assignedWorkerIds;
  final DateTime? startedAt;
  final DateTime? completedAt;

  JobStep({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.status,
    required this.assignedWorkerIds,
    this.startedAt,
    this.completedAt,
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
      orderIndex: json['orderIndex'] ?? 0,
      status: mappedStatus,
      assignedWorkerIds: List<int>.from(json['assignedWorkerIds'] ?? []),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
    );
  }

  bool isAssignedTo(int workerId) => assignedWorkerIds.contains(workerId);
}
