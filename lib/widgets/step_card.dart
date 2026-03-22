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
    final jobAddress = jobData.jobAddress;

    // Fallbacks for safety
    final statusColor = step.status.color ?? Colors.blue;
    final statusBgColor = step.status.backgroundColor ?? Colors.blue.shade50;

    // Dynamic Date Configuration
    String? dateStr;
    IconData? dateIcon;
    Color? dateColor;

    if (step.completedAt != null) {
      dateStr =
          "Completed: ${DateFormat('MMM dd, HH:mm').format(step.completedAt!)}";
      dateIcon = Icons.task_alt_rounded;
      dateColor = Colors.green.shade600;
    } else if (step.startedAt != null) {
      dateStr =
          "Started: ${DateFormat('MMM dd, HH:mm').format(step.startedAt!)}";
      dateIcon = Icons.access_time_rounded;
      dateColor = Colors.blue.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          // If selected, give it a beautiful blue glow. Otherwise, standard soft shadow.
          if (isSelected)
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          else ...[
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ],
      ),
      // ClipRRect ensures the ripple effect stays inside the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: statusColor.withOpacity(0.1),
            highlightColor: statusColor.withOpacity(0.05),
            child: Stack(
              children: [
                // --- THE ACCENT LINE ---
                // Using Positioned instead of IntrinsicHeight is much better for ListView performance
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                ),

                // --- MAIN CONTENT ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "JOB #${jobData.jobId} • STEP #${step.orderIndex}",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  step.status.label.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- TITLE & DESCRIPTION ---
                      Text(
                        step.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.3,
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
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],

                      // --- META INFO SECTION (Customer & Location) ---
                      if ((customer != null && customer.name.isNotEmpty) ||
                          jobAddress != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors
                                .grey
                                .shade50, // Lighter, cleaner background
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer Name
                              if (customer != null &&
                                  customer.name.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                      color: Colors.blue.shade400,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        customer.name,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (customer != null &&
                                  customer.name.isNotEmpty &&
                                  jobAddress != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(height: 1),
                                ),

                              // Job Address
                              if (jobAddress != null) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        jobAddress.fullAddress,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          height: 1.4,
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

                      // --- DATE INFO FOOTER ---
                      if (dateStr != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: dateColor!.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(dateIcon, size: 14, color: dateColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: dateColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
