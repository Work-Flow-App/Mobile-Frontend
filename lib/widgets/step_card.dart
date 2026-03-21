import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:intl/intl.dart';

class StepCard extends StatelessWidget {
  final JobData jobData;
  final VoidCallback onTap;
  final bool isSelected;

  const StepCard({
    super.key,
    required this.jobData,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final step = jobData.step;
    final customer = jobData.customer;
    final jobAddress = jobData.jobAddress; // Extract the new jobAddress
    final statusColor = step.status.color;
    final statusBgColor = step.status.backgroundColor;

    // Dynamic Date Configuration
    String? dateStr;
    IconData? dateIcon;
    Color? dateColor;

    if (step.completedAt != null) {
      dateStr =
          "Completed: ${DateFormat('MMM dd, HH:mm').format(step.completedAt!)}";
      dateIcon = Icons.task_alt; // Green checkmark for completed
      dateColor = Colors.green.shade600;
    } else if (step.startedAt != null) {
      dateStr =
          "Started: ${DateFormat('MMM dd, HH:mm').format(step.startedAt!)}";
      dateIcon = Icons.access_time; // Blue clock for started/in-progress
      dateColor = Colors.blue.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Modern soft shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Accent Line matching status color
                  Container(width: 5, color: statusColor),

                  // Main Card Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- HEADER ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "JOB #${jobData.jobId}  •  STEP #${step.orderIndex}",
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontSize: 11,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  step.status.label.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // --- TITLE & DESCRIPTION ---
                          Text(
                            step.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                          if (step.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],

                          // --- SERVICE INFO SECTION ---
                          // Check for either a customer name or a job address
                          if ((customer != null && customer.name.isNotEmpty) ||
                              jobAddress != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blueGrey.shade100.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Customer Name
                                  if (customer != null &&
                                      customer.name.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            customer.name,
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade900,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Add spacing if we also have an address
                                    if (jobAddress != null)
                                      const SizedBox(height: 8),
                                  ],

                                  // 2. Job Address (Service Location)
                                  if (jobAddress != null) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.red.shade400,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            jobAddress.fullAddress,
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade700,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          // --- DATE INFO ---
                          if (dateStr != null) ...[
                            const SizedBox(height: 16),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(dateIcon, size: 16, color: dateColor),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: dateColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
