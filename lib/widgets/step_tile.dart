import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/job_model.dart';

class StepTile extends StatelessWidget {
  final JobStep step;
  final bool isLast;
  final int currentWorkerId;
  final VoidCallback onTap;

  const StepTile({
    super.key,
    required this.step,
    required this.isLast,
    required this.currentWorkerId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.status == StepStatus.COMPLETED;
    final isAssignedToMe = step.isAssignedTo(currentWorkerId);

    // 1. Determine Circle Colors
    final indicatorColor = step.status.indicatorColor;
    final indicatorTextColor = step.status.indicatorTextColor;
    final borderColor = step.status == StepStatus.NOT_STARTED
        ? Colors.grey.shade400
        : indicatorColor;

    // 2. Determine Line Color ("The Flow")
    // If this step is completed, the line flowing OUT of it should be green.
    // If this step is Pending, the line flowing OUT is red (blocked).
    // Otherwise, it's grey (hasn't flowed past here yet).
    Color lineColor;
    switch (step.status) {
      case StepStatus.COMPLETED:
        lineColor = Colors.green.shade700;
        break;
      case StepStatus.PENDING:
        lineColor = Colors.red.shade700;
        break;
      default:
        lineColor = Colors.grey.shade300;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TIMELINE INDICATOR COLUMN ---
          Column(
            children: [
              // The Circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: indicatorColor,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    if (step.status == StepStatus.STARTED)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: _buildIconOrNumber(isCompleted, indicatorTextColor),
                ),
              ),
              // The Line (Flow)
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 4, // Slightly thicker for better visibility
                    color: lineColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // --- TEXT CONTENT ---
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0, top: 4, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${step.orderIndex}. ${step.name}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: step.status == StepStatus.NOT_STARTED
                            ? Colors.black87
                            : step.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Small Status Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: step.status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: step.status.color.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            step.status.name.split('.').last,
                            style: TextStyle(
                              color: step.status.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAssignedToMe && !isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "YOU",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOrNumber(bool isCompleted, Color textColor) {
    if (isCompleted) {
      return Icon(Icons.check, color: textColor, size: 24);
    } else if (step.status == StepStatus.PENDING) {
      return Icon(Icons.priority_high_rounded, color: textColor, size: 24);
    } else if (step.status == StepStatus.STARTED) {
      return Icon(Icons.play_arrow_rounded, color: textColor, size: 28);
    } else {
      return Text(
        "${step.orderIndex}",
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }
  }
}
