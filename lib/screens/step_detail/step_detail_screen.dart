import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';

enum TimelineFilter { all, comments, attachments }

class StepDetailScreen extends ConsumerStatefulWidget {
  final JobStep step;

  const StepDetailScreen({super.key, required this.step});

  @override
  ConsumerState<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends ConsumerState<StepDetailScreen> {
  late JobStep step;
  final commentController = TextEditingController();
  bool isLoadingAction = false;
  TimelineFilter _currentFilter = TimelineFilter.all; // Filter State

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

  // --- ACTIONS ---

  Future<void> _handleRefresh() async {
    // Refreshes discussion  and global job list [cite: 17]
    ref.refresh(stepTimelineProvider(step.id));
    return ref.refresh(jobsFutureProvider);
  }

  Future<void> _startStep() async {
    setState(() => isLoadingAction = true);
    try {
      await ref.read(jobServiceProvider).startStep(step.id); //
      // Update local state to reflect change immediately
      setState(() {
        // Create new object with updated status to trigger UI rebuild
        // We reuse properties but change status to STARTED [cite: 20]
        // Note: In a real app with immutable models, use copyWith
        step = JobStep(
          id: step.id,
          name: step.name,
          description: step.description,
          orderIndex: step.orderIndex,
          status: StepStatus.STARTED,
          assignedWorkerIds: step.assignedWorkerIds,
        );
      });
      _handleRefresh();
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
      await ref.read(jobServiceProvider).completeStep(step.id); //
      setState(() {
        step = JobStep(
          id: step.id,
          name: step.name,
          description: step.description,
          orderIndex: step.orderIndex,
          status: StepStatus.COMPLETED,
          assignedWorkerIds: step.assignedWorkerIds,
        );
      });
      _handleRefresh();
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
      await ref
          .read(jobServiceProvider)
          .addComment(step.id, text.trim()); // [cite: 23]
      commentController.clear();
      ref.refresh(stepTimelineProvider(step.id));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _addAttachmentMock(String mockFilePath) async {
    // In production, use file_picker to get actual path.
    // Logic: User picks file -> App gets path -> Service uploads -> Refresh timeline [cite: 25]
    try {
      // await ref.read(jobServiceProvider).addAttachment(step.id, mockFilePath);
      // ref.refresh(stepTimelineProvider(step.id));
      _addComment("Simulated Attachment Upload: $mockFilePath");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

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
                  _addAttachmentMock("/camera/img.jpg");
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _addAttachmentMock("/gallery/img.jpg");
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
    // RBAC Check [cite: 18]
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

  // --- INFO SECTION ---
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
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
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

  // --- TIMELINE SECTION ---
  Widget _buildTimelineSection(bool canEdit) {
    final timelineAsync = ref.watch(stepTimelineProvider(step.id));

    return Column(
      children: [
        // FILTER HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Activity",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              // Filter Chips
              Row(
                children: [
                  _buildFilterChip("All", TimelineFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip("Comments", TimelineFilter.comments),
                  const SizedBox(width: 8),
                  _buildFilterChip("Files", TimelineFilter.attachments),
                ],
              ),
            ],
          ),
        ),

        // TIMELINE LIST
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (events) {
                // APPLY LOCAL FILTER
                final filteredEvents = events.where((e) {
                  if (_currentFilter == TimelineFilter.comments)
                    return e.itemType == TimelineItemType.COMMENT;
                  if (_currentFilter == TimelineFilter.attachments)
                    return e.itemType == TimelineItemType.ATTACHMENT;
                  return true;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text("No activity found.")),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineItem(
                        filteredEvents[index] as TimelineEvent,
                        index == filteredEvents.length - 1,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // INPUT AREA
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

  Widget _buildFilterChip(String label, TimelineFilter filter) {
    final isSelected = _currentFilter == filter;
    return InkWell(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    final time = DateFormat.jm().format(event.createdAt);
    // Check extension for image display
    final bool hasImage =
        event.fileUrl != null &&
        (event.fileUrl!.toLowerCase().contains('.jpg') ||
            event.fileUrl!.toLowerCase().contains('.jpeg') ||
            event.fileUrl!.toLowerCase().contains('.png'));

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
                        event.actorId == 5 ? "You" : "User #${event.actorId}",
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
                      constraints: const BoxConstraints(maxWidth: 250),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Real Image Rendering
                          if (hasImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                event.fileUrl!, // [cite: 30]
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, progress) =>
                                    progress == null
                                    ? child
                                    : Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                errorBuilder: (ctx, err, stack) =>
                                    const SizedBox(
                                      height: 100,
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          else
                            // File View/Download UI
                            ListTile(
                              leading: Icon(
                                Icons.description,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                event.content.isNotEmpty
                                    ? event.content
                                    : "Attachment",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: const Text(
                                "Tap to view",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                // In a real app, use url_launcher: launchUrl(Uri.parse(event.fileUrl!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Opening ${event.content}...",
                                    ),
                                  ),
                                );
                              },
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
