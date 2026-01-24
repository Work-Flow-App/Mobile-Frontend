import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';

class StepDetailScreen extends StatefulWidget {
  final JobStep step;

  const StepDetailScreen({super.key, required this.step});

  @override
  State<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends State<StepDetailScreen>
    with TickerProviderStateMixin {
  late JobStep step;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    step = widget.step;
  }

  // 1. Logic to Start the step
  void _startStep() {
    setState(() {
      step = JobStep(
        id: step.id,
        name: step.name,
        description: step.description,
        orderIndex: step.orderIndex,
        status: StepStatus.STARTED,
        assignedWorkerIds: step.assignedWorkerIds,
        mockTimelineEvents: step.mockTimelineEvents,
      );

      step.mockTimelineEvents.add(
        TimelineEvent(
          username: "You",
          timestamp: DateTime.now(),
          content: "Started this step",
        ),
      );
    });
  }

  // 2. Logic to Complete the step
  void _markAsCompleted() {
    setState(() {
      step = JobStep(
        id: step.id,
        name: step.name,
        description: step.description,
        orderIndex: step.orderIndex,
        status: StepStatus.COMPLETED,
        assignedWorkerIds: step.assignedWorkerIds,
        mockTimelineEvents: step.mockTimelineEvents,
      );

      step.mockTimelineEvents.add(
        TimelineEvent(
          username: "You",
          timestamp: DateTime.now(),
          content: "Marked this step as COMPLETED",
        ),
      );
    });
  }

  void _addComment(String text, {bool isAttachment = false}) {
    if (text.trim().isEmpty) return;

    setState(() {
      step.mockTimelineEvents.add(
        TimelineEvent(
          username: "You",
          timestamp: DateTime.now(),
          content: text.trim(),
          isAttachment: isAttachment,
        ),
      );
    });

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Step: ${step.name}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, step),
        ),
        actions: const [FloowLogo()],
      ),
      body: Column(
        children: [
          // -------- Step Info --------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  "Status: ${step.status.name}",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),

                // -------- BUTTON LOGIC --------
                if (step.status == StepStatus.NOT_STARTED)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue.shade700, // Blue background
                        foregroundColor: Colors.white, // WHITE TEXT
                      ),
                      child: const Text("Start Step"),
                    ),
                  )
                else if (step.status == StepStatus.STARTED)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _markAsCompleted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green.shade700, // Green background
                        foregroundColor: Colors.white, // WHITE TEXT
                      ),
                      child: const Text("Mark as Completed"),
                    ),
                  ),
                // If PENDING or COMPLETED, no button is shown
              ],
            ),
          ),

          const Divider(height: 1),

          // -------- Timeline --------
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Activity Timeline",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: step.mockTimelineEvents.length,
                      itemBuilder: (context, index) {
                        final event = step.mockTimelineEvents[index];
                        final isLast =
                            index == step.mockTimelineEvents.length - 1;
                        return _buildTimelineItem(event, isLast);
                      },
                    ),
                  ),

                  // -------- Chat Input --------
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: SafeArea(
                      top: false,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Add a comment or attachment...",
                                  hintStyle: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () =>
                                  _addComment(commentController.text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () => _addComment(
                                "New_Attachment.jpg",
                                isAttachment: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    final time = DateFormat.jm().format(event.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[400],
                child: const Icon(Icons.person, color: Colors.black87),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (event.isAttachment)
                    Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Center(
                        child: Text(
                          event.content,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    )
                  else
                    Text(
                      event.content,
                      style: const TextStyle(color: Colors.black87),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
