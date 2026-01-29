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

class _StepDetailScreenState extends ConsumerState<StepDetailScreen> {
  late JobStep step;
  final commentController = TextEditingController();
  bool isLoadingAction = false; // To show loading on buttons

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

  // --- API LOGIC METHODS ---

  Future<void> _startStep() async {
    setState(() => isLoadingAction = true);
    try {
      // Call API [cite: 3]
      await ref.read(jobServiceProvider).startStep(step.id);

      // Update Local State
      setState(() {
        step = JobStep(
          id: step.id,
          name: step.name,
          description: step.description,
          orderIndex: step.orderIndex,
          status: StepStatus.STARTED, // Update status
          assignedWorkerIds: step.assignedWorkerIds,
          mockTimelineEvents: step.mockTimelineEvents,
        );
      });
      // Optionally refresh global job list to sync
      ref.refresh(jobsFutureProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoadingAction = false);
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() => isLoadingAction = true);
    try {
      // Call API [cite: 5]
      await ref.read(jobServiceProvider).completeStep(step.id);

      setState(() {
        step = JobStep(
          id: step.id,
          name: step.name,
          description: step.description,
          orderIndex: step.orderIndex,
          status: StepStatus.COMPLETED, // Update status
          assignedWorkerIds: step.assignedWorkerIds,
          mockTimelineEvents: step.mockTimelineEvents,
        );
      });
      ref.refresh(jobsFutureProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoadingAction = false);
    }
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;
    try {
      // Call API [cite: 7]
      await ref.read(jobServiceProvider).addComment(step.id, text.trim());
      commentController.clear();
      // Refresh the timeline provider to show new comment
      ref.refresh(stepTimelineProvider(step.id));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending comment: $e")));
    }
  }

  // Note: For real file picking you need 'file_picker' or 'image_picker' package.
  // Here we simulate the path for the logic.
  Future<void> _addAttachmentMock(String mockFilePath) async {
    try {
      // This will fail without a real file on device, but logic is correct [cite: 9]
      // await ref.read(jobServiceProvider).addAttachment(step.id, mockFilePath);

      // For demo, we just add a comment saying we attached something
      _addComment("Simulated Attachment: $mockFilePath");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error uploading: $e")));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 600),
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
                  _addAttachmentMock("/path/to/camera/photo.jpg");
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _addAttachmentMock("/path/to/gallery/image.jpg");
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
        _buildInfoSection(canEdit),
        const Divider(height: 1),
        Expanded(child: _buildTimelineSection(canEdit)),
      ],
    );
  }

  Widget _buildSplitLayout(bool canEdit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(child: _buildInfoSection(canEdit)),
        ),
        const VerticalDivider(width: 1),
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
              color: step.status.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Status: ${step.status.name}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: step.status.color,
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
            if (isLoadingAction)
              const Center(child: CircularProgressIndicator())
            else if (step.status == StepStatus.NOT_STARTED)
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
    // Watch the Timeline Provider
    final timelineAsync = ref.watch(stepTimelineProvider(step.id));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[200],
          child: Text(
            "Discussion & Activity",
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
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text("Error loading history: $err")),
              data: (events) {
                if (events.isEmpty) {
                  return const Center(child: Text("No activity yet."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    // Since dynamic list from provider, cast carefully
                    final isLast = index == events.length - 1;
                    return _buildTimelineItem(event as TimelineEvent, isLast);
                  },
                );
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          // If fileUrl is set, ideally show an Image.network here
                          if (event.fileUrl != null &&
                              (event.fileUrl!.endsWith(".jpg") ||
                                  event.fileUrl!.endsWith(".png")))
                            Image.network(
                              event.fileUrl!,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.broken_image),
                            )
                          else
                            Text(
                              event.content,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
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
