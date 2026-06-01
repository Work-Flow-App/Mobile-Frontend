import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/job_model.dart';

class SlaTrackerWidget extends StatelessWidget {
  final JobStep step;
  final bool
  compact; // If true, renders smaller for the Card. If false, renders large for details.

  const SlaTrackerWidget({super.key, required this.step, this.compact = false});

  // The math logic
  String _calculateRemainingTime() {
    if (step.status == StepStatus.COMPLETED) return "Finished";
    if (step.startedAt == null || step.maximumDurationMinutes <= 0)
      return "No deadline now";

    // 1 & 2. Calculate exact deadline
    final deadlineTime = step.startedAt!.add(
      Duration(minutes: step.maximumDurationMinutes),
    );

    // 3. Find difference
    final now = DateTime.now();
    final difference = deadlineTime.difference(now);

    if (difference.isNegative) {
      return "SLA Breached!";
    }

    // 4. Format to Days / Hours / Minutes / Seconds
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60; // NEW: Calculate seconds

    // NEW: Format the string to include seconds
    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m ${seconds}s remaining";
    }
    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s remaining";
    }
    return "${minutes}m ${seconds}s remaining";
  }

  @override
  Widget build(BuildContext context) {
    if (step.slaStatus == SlaStatus.NOT_APPLICABLE &&
        step.maximumDurationMinutes <= 0) {
      return const SizedBox.shrink(); // Hide if completely N/A
    }

    final color = step.slaStatus.color;
    final icon = step.slaStatus.icon;

    // Use a stream to update the text every minute without setState on the whole screen
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final remainingText = _calculateRemainingTime();
        final isBreached = remainingText == "SLA Breached!";

        if (compact) {
          // Compact UI for StepCard
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isBreached ? Colors.red.shade50 : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBreached
                    ? Colors.red.shade200
                    : color.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isBreached ? Colors.red.shade700 : color,
                ),
                const SizedBox(width: 6),
                Text(
                  remainingText,
                  style: TextStyle(
                    color: isBreached ? Colors.red.shade700 : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        // Expanded UI for StepInfoSection
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.slaStatus.label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remainingText,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
