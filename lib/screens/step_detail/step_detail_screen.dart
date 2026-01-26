import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';

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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 600), // constrain modal width
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
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AppBranding(color: Colors.white, size: 24, fontSize: 18),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint for Tablet/Desktop (Split View)
          if (constraints.maxWidth > 800) {
            return _buildSplitLayout(canEdit);
          } else {
            return _buildMobileLayout(canEdit);
          }
        },
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildMobileLayout(bool canEdit) {
    return Column(
      children: [
        // Info Section
        _buildInfoSection(canEdit),
        const Divider(height: 1),
        // Timeline Section (Takes remaining space)
        Expanded(child: _buildTimelineSection(canEdit)),
      ],
    );
  }

  Widget _buildSplitLayout(bool canEdit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side: Info (Fixed Width or Flex)
        SizedBox(
          width: 400,
          child: SingleChildScrollView(child: _buildInfoSection(canEdit)),
        ),
        const VerticalDivider(width: 1),
        // Right Side: Timeline (Expanded)
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _buildTimelineSection(canEdit),
          ),
        ),
      ],
    );
  }

  // --- SECTIONS ---

  Widget _buildInfoSection(bool canEdit) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: step.status == StepStatus.COMPLETED
                  ? Colors.green.shade100
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Status: ${step.status.name}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: step.status == StepStatus.COMPLETED
                    ? Colors.green.shade800
                    : Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 32),

          // --- ACTION BUTTONS ---
          if (canEdit) ...[
            if (step.status == StepStatus.NOT_STARTED)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startStep,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start Step"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (step.status == StepStatus.STARTED)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markAsCompleted,
                  icon: const Icon(Icons.check),
                  label: const Text("Mark as Completed"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ] else ...[
            // Read Only Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildTimelineSection(bool canEdit) {
    return Column(
      children: [
        // Timeline Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[200],
          child: Text(
            "Activity Timeline",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),

        // List
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: step.mockTimelineEvents.length,
              itemBuilder: (context, index) {
                final event = step.mockTimelineEvents[index];
                final isLast = index == step.mockTimelineEvents.length - 1;
                return _buildTimelineItem(event, isLast);
              },
            ),
          ),
        ),

        // Input Area
        if (canEdit)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: commentController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: "Add a comment...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _addComment(commentController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
                radius: 16,
                backgroundColor: Colors.white,
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
                        color: Colors.white,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        // Simulating a chat bubble
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        event.content,
                        style: const TextStyle(fontSize: 15, height: 1.4),
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
