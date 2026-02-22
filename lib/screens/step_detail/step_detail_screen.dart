import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_controller.dart';
import 'package:mobile_frontend/screens/step_detail/step_info_section.dart';
import 'package:mobile_frontend/screens/step_detail/timeline_item_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

enum TimelineFilter { all, comments, attachments }

class StepDetailScreen extends ConsumerStatefulWidget {
  final JobStep step;

  const StepDetailScreen({super.key, required this.step});

  @override
  ConsumerState<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends ConsumerState<StepDetailScreen> {
  final commentController = TextEditingController();
  TimelineFilter _currentFilter = TimelineFilter.all;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get State from Controller
    final screenState = ref.watch(stepDetailControllerProvider(widget.step));
    final currentStep = screenState.step;

    // 2. Auth Logic
    /* final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;
    final authState = ref.watch(authNotifierProvider); */

    /* final isAdmin = authState.role == 'ADMIN';
    final isAssigned = currentStep.isAssignedTo(currentWorkerId); */
    final canEdit = true;

    return Scaffold(
      appBar: AppBar(
        title: Text("Step: ${currentStep.name}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, currentStep),
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
            return _buildSplitLayout(
              currentStep,
              canEdit,
              screenState.isLoading,
            );
          } else {
            return _buildMobileLayout(
              currentStep,
              canEdit,
              screenState.isLoading,
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(JobStep step, bool canEdit, bool isLoading) {
    return Column(
      children: [
        StepInfoSection(step: step, canEdit: canEdit, isLoading: isLoading),
        const Divider(height: 1),
        Expanded(child: _buildTimelineSection(step, canEdit)),
      ],
    );
  }

  Widget _buildSplitLayout(JobStep step, bool canEdit, bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: StepInfoSection(
              step: step,
              canEdit: canEdit,
              isLoading: isLoading,
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _buildTimelineSection(step, canEdit),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(JobStep step, bool canEdit) {
    final timelineAsync = ref.watch(stepTimelineProvider(step.id));
    final controller = ref.read(
      stepDetailControllerProvider(widget.step).notifier,
    );
    final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;

    return Column(
      children: [
        // Header & Filters
        _buildTimelineHeader(),

        // List
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (events) {
                final filteredEvents = _applyFilters(events);

                if (filteredEvents.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.refreshTimeline,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text("No activity.")),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshTimeline,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) => TimelineItemWidget(
                      event: filteredEvents[index] as TimelineEvent,
                      isLast: index == filteredEvents.length - 1,
                      currentWorkerId: currentWorkerId,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Input Area
        if (canEdit) _buildInputArea(controller),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
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
    );
  }

  Widget _buildInputArea(StepDetailController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () => _showAttachmentOptions(controller),
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
                  maxLines: 5,
                  minLines: 1,
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
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () async {
                  try {
                    await controller.addComment(commentController.text);
                    commentController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> events) {
    return events.where((e) {
      if (_currentFilter == TimelineFilter.comments) {
        return e.itemType == TimelineItemType.COMMENT;
      }
      if (_currentFilter == TimelineFilter.attachments) {
        return e.itemType == TimelineItemType.ATTACHMENT;
      }
      return true;
    }).toList();
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

  void _showAttachmentOptions(StepDetailController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              _buildAttachmentOption(
                Icons.camera_alt,
                Colors.blue,
                'Take Photo',
                () async {
                  final picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) controller.uploadFile(photo.path);
                },
              ),
              _buildAttachmentOption(
                Icons.photo_library,
                Colors.purple,
                'Gallery',
                () async {
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) controller.uploadFile(image.path);
                },
              ),
              _buildAttachmentOption(
                Icons.insert_drive_file,
                Colors.orange,
                'Document',
                () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles();
                  if (result != null)
                    controller.uploadFile(result.files.single.path!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    Color color,
    String text,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
