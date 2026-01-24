import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';

class StepDetailScreen extends ConsumerStatefulWidget {
  final JobStep step;

  const StepDetailScreen({super.key, required this.step});

  @override
  ConsumerState<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends ConsumerState<StepDetailScreen>
    with TickerProviderStateMixin {
  late JobStep step;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    step = widget.step;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

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

  // --- NEW: Attachment Modal ---
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _addComment("Captured_Photo.jpg", isAttachment: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _addComment("Gallery_Image.jpg", isAttachment: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.orange),
                title: const Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  _addComment("Document.pdf", isAttachment: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // RBAC & Logic Variables
    final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.role == 'ADMIN';
    final isAssigned = step.isAssignedTo(currentWorkerId);
    final canEdit = isAdmin || isAssigned;

    return Scaffold(
      appBar: AppBar(
        title: Text("Step: ${step.name}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, step),
        ),
        actions: const [
          // FIX: Pass White color
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AppBranding(color: Colors.white, size: 24, fontSize: 18),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- STEP INFO HEADER ---
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

                // --- ACTION BUTTONS (RBAC Controlled) ---
                if (canEdit) ...[
                  if (step.status == StepStatus.NOT_STARTED)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
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
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Mark as Completed"),
                      ),
                    ),
                ] else ...[
                  // Read Only Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "View Only (Not Assigned)",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // --- ACTIVITY TIMELINE ---
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: step.mockTimelineEvents.length,
                itemBuilder: (context, index) {
                  final event = step.mockTimelineEvents[index];
                  final isLast = index == step.mockTimelineEvents.length - 1;
                  return _buildTimelineItem(event, isLast);
                },
              ),
            ),
          ),

          // --- CHAT INPUT AREA ---
          // Only show input if user has permission to edit
          if (canEdit)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 5,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment Button
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _showAttachmentOptions,
                    ),

                    // Expanded Text Field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: commentController,
                          // FIX: Enabling multiline expansion
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          minLines: 1,
                          maxLines: 5, // Grows up to 5 lines, then scrolls
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical:
                                  10, // Adjusted padding for better centering
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Send Button
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => _addComment(commentController.text),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- TIMELINE ITEM WIDGET ---
  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    final time = DateFormat.jm().format(event.timestamp);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (event.isAttachment)
                    Container(
                      height: 120,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image, color: Colors.grey, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            event.content,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        event.content,
                        style: const TextStyle(fontSize: 15, height: 1.3),
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
}
