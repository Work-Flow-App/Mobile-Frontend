import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:intl/intl.dart';

class SlaTrackerWidget extends StatelessWidget {
  final JobStep step;
  final bool compact;

  const SlaTrackerWidget({super.key, required this.step, this.compact = false});

  // --- Helper: Format a Duration into a beautiful string ---
  String _formatDuration(Duration duration) {
    if (duration.isNegative) duration = -duration;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) return "${days}d ${hours}h ${minutes}m";
    if (hours > 0) return "${hours}h ${minutes}m ${seconds}s";
    return "${minutes}m ${seconds}s";
  }

  // --- Helper: Format static minutes into a string ---
  String _formatMinutes(int totalMinutes) {
    final duration = Duration(minutes: totalMinutes);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final mins = duration.inMinutes % 60;

    if (days > 0) return "${days}d ${hours}h ${mins}m";
    if (hours > 0) return "${hours}h ${mins}m";
    return "${mins}m";
  }

  @override
  Widget build(BuildContext context) {
    if (step.slaStatus == SlaStatus.NOT_APPLICABLE &&
        step.maximumDurationMinutes <= 0) {
      return const SizedBox.shrink();
    }

    // Use a stream to update the text & progress bar every second natively
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        // --- Core Math Logic ---
        final now = DateTime.now();
        final isCompleted = step.status == StepStatus.COMPLETED;
        final endTime = isCompleted ? (step.completedAt ?? now) : now;

        Duration elapsed = Duration.zero;
        if (step.startedAt != null) {
          elapsed = endTime.difference(step.startedAt!);
        }

        final int limitMinutes = step.maximumDurationMinutes;
        final Duration limitDuration = Duration(minutes: limitMinutes);
        final Duration remaining = limitDuration - elapsed;

        final bool isBreached =
            step.slaStatus == SlaStatus.BREACHED || remaining.isNegative;

        final Color statusColor = isBreached
            ? Colors.red.shade600
            : Colors.teal.shade600;
        final Color bgColor = isBreached
            ? Colors.red.shade50
            : Colors.teal.shade50;
        final IconData statusIcon = isBreached
            ? Icons.error_outline_rounded
            : Icons.check_circle_outline_rounded;

        // -------------------------------------------------------------
        // COMPACT VIEW (For the list cards - simple text & icon)
        // -------------------------------------------------------------
        if (compact) {
          String compactText;
          if (isCompleted) {
            compactText = "Finished";
          } else if (step.startedAt == null || limitMinutes <= 0) {
            compactText = "No deadline";
          } else {
            compactText = "${_formatDuration(remaining)} remaining";
            if (isBreached) compactText = "SLA Breached!";
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isBreached
                  ? Colors.red.shade50
                  : step.slaStatus.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isBreached
                    ? Colors.red.shade200
                    : step.slaStatus.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBreached ? Icons.error_outline : step.slaStatus.icon,
                  size: 14,
                  color: isBreached
                      ? Colors.red.shade700
                      : step.slaStatus.color,
                ),
                const SizedBox(width: 6),
                Text(
                  compactText,
                  style: TextStyle(
                    color: isBreached
                        ? Colors.red.shade700
                        : step.slaStatus.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        // -------------------------------------------------------------
        // DETAILED VIEW (For StepInfoSection - beautiful progress bar)
        // -------------------------------------------------------------

        // Progress Calculation (0.0 to 1.0)
        double progress = 0.0;
        if (limitMinutes > 0 && step.startedAt != null) {
          progress = (elapsed.inSeconds / limitDuration.inSeconds).clamp(
            0.0,
            1.0,
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Step SLA Tracker",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBreached
                          ? "BREACHED"
                          : (isCompleted ? "COMPLETED" : "ON TRACK"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Dynamic Stats Grid ---
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  _buildStat(
                    "Started At",
                    step.startedAt != null
                        ? DateFormat('MMM dd, HH:mm').format(step.startedAt!)
                        : "Not Started",
                    Icons.play_circle_outline,
                    statusColor,
                  ),
                  _buildStat(
                    "Time Spent",
                    step.startedAt != null ? _formatDuration(elapsed) : "0m 0s",
                    Icons.timer_outlined,
                    statusColor,
                  ),
                  if (limitMinutes > 0)
                    _buildStat(
                      isBreached ? "Overdue By" : "Remaining",
                      _formatDuration(remaining),
                      isBreached
                          ? Icons.warning_amber_rounded
                          : Icons.hourglass_bottom_rounded,
                      statusColor,
                    ),
                  if (limitMinutes > 0)
                    _buildStat(
                      "SLA Limit",
                      _formatMinutes(limitMinutes),
                      Icons.flag_outlined,
                      statusColor,
                    ),
                ],
              ),

              // --- Progress Bar ---
              if (limitMinutes > 0 && step.startedAt != null) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: statusColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widget for the Stats underneath the SLA title ---
  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
