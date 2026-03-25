import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart'; // Added for the SliverAppBar actions

class TaskStatsScreen extends ConsumerWidget {
  const TaskStatsScreen({super.key});

  // Helper to map an icon to each of your 7 statuses
  IconData _getIconForStatus(StepStatus status) {
    switch (status) {
      case StepStatus.COMPLETED:
        return Icons.check_circle_rounded;
      case StepStatus.ONGOING:
      case StepStatus.STARTED:
        return Icons.autorenew_rounded;
      case StepStatus.PENDING:
        return Icons.warning_rounded;
      case StepStatus.SKIPPED:
        return Icons.next_plan_rounded;
      case StepStatus.INITIATED:
        return Icons.flare_rounded;
      case StepStatus.NOT_STARTED:
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(assignedStepsFutureProvider);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Matches your HomeDashboard
      body: stepsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          // Wrap everything in the NestedScrollView to match HomeDashboard
          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      title: const Text(
                        "Task Overview",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      floating: true,
                      snap: true,
                      pinned: false,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      foregroundColor:
                          Colors.black, // Makes the back button black
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.3),
                      actions: const [
                        Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: AppBranding(
                            color: Colors.black,
                            size: 24,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ];
                },
            body: Builder(
              builder: (context) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks available to analyze.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // --- Dynamically Calculate Statistics ---
                final total = tasks.length;

                // Create a map to hold the count for all 7 statuses
                final Map<StepStatus, int> statusCounts = {
                  for (var status in StepStatus.values) status: 0,
                };

                // Populate the counts
                for (var task in tasks) {
                  statusCounts[task.step.status] =
                      (statusCounts[task.step.status] ?? 0) + 1;
                }

                // --- Completion Percentage ---
                final completedCount = statusCounts[StepStatus.COMPLETED] ?? 0;
                final percentComplete = total > 0
                    ? (completedCount / total)
                    : 0.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    final crossAxisCount = isTablet ? 4 : 2;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Hero Card (Total Progress) ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.black, Color(0xFF333333)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Overall Completion",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${(percentComplete * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: percentComplete,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.greenAccent,
                                      ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "$completedCount of $total tasks finished",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- Section Title ---
                          const Text(
                            "Task Breakdown",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- Responsive Grid dynamically showing all 7 types ---
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                ),
                            itemCount: StepStatus.values.length,
                            itemBuilder: (context, index) {
                              final status = StepStatus.values[index];
                              final count = statusCounts[status] ?? 0;

                              return _StatCard(
                                title: status.label,
                                count: count,
                                icon: _getIconForStatus(status),
                                color: status.color,
                                backgroundColor: status.backgroundColor,
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // --- Visual Bar Chart (Dynamically generating all 7 rows) ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Status Distribution",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Dynamically map all 7 statuses to BarRows
                                ...StepStatus.values.map((status) {
                                  return _BarRow(
                                    title: status.label,
                                    count: statusCounts[status] ?? 0,
                                    total: total,
                                    color: status.color,
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- Helper Widgets for the UI ---

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String title;
  final int count;
  final int total;
  final Color color;

  const _BarRow({
    required this.title,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final flexCompleted = count;
    final flexRemaining = total > count ? total - count : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (flexCompleted > 0)
                    Expanded(
                      flex: flexCompleted,
                      child: Container(height: 8, color: color),
                    ),
                  if (flexRemaining > 0)
                    Expanded(
                      flex: flexRemaining,
                      child: Container(height: 8, color: Colors.grey.shade200),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
