import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_controller.dart';
import 'package:mobile_frontend/screens/step_detail/step_info_section.dart';
import 'package:mobile_frontend/screens/step_detail/timeline_item_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class StepDetailScreen extends ConsumerStatefulWidget {
  final JobStep step;

  const StepDetailScreen({super.key, required this.step});

  @override
  ConsumerState<StepDetailScreen> createState() => _StepDetailScreenState();
}

class _StepDetailScreenState extends ConsumerState<StepDetailScreen> {
  // Helper method to show a confirmation dialog
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        onConfirm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenState = ref.watch(stepDetailControllerProvider(widget.step));
    final controller = ref.read(
      stepDetailControllerProvider(widget.step).notifier,
    );
    final currentStep = screenState.step;
    final canEdit = true; // Based on your auth logic

    return Scaffold(
      // Stacked Floating Action Buttons
      floatingActionButton: _buildFloatingActionButtons(
        context,
        currentStep,
        canEdit,
        screenState.isLoading,
        controller,
      ),

      // NEW: Wrapped body in NestedScrollView for the dynamic AppBar effect
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(
                "Step: ${currentStep.name}",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, currentStep),
              ),
              floating: true, // Appears as soon as you scroll up
              snap: true, // Snaps fully into view
              pinned:
                  false, // Scrolls completely out of view when scrolling down
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Colors.black,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.3),
              actions: [
                // Manual refresh button in AppBar
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh Step Info",
                  onPressed: () => controller.refreshStepData(),
                ),
                const Padding(
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildSplitLayout(
                currentStep,
                canEdit,
                screenState.isLoading,
                controller,
              );
            } else {
              return _buildMobileLayout(
                currentStep,
                canEdit,
                screenState.isLoading,
                controller,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(
    BuildContext context,
    JobStep step,
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (canEdit) ...[
          if (isLoading)
            const FloatingActionButton.extended(
              heroTag: "loading_btn",
              onPressed: null,
              label: CircularProgressIndicator(),
            )
          else if (step.status == StepStatus.NOT_STARTED)
            FloatingActionButton.extended(
              heroTag: "start_step_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Start Step",
                  content: "Are you sure you want to start this step?",
                  onConfirm: () async {
                    try {
                      await controller.startStep();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Step"),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            )
          else if (step.status == StepStatus.STARTED)
            FloatingActionButton.extended(
              heroTag: "complete_step_btn",
              onPressed: () {
                _showConfirmationDialog(
                  context: context,
                  title: "Complete Step",
                  content:
                      "Are you sure you want to mark this step as completed?",
                  onConfirm: () async {
                    try {
                      await controller.completeStep();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                );
              },
              icon: const Icon(Icons.check),
              label: const Text("Mark as Completed"),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton.extended(
          heroTag: "comments_btn",
          onPressed: () {
            _showCommentsBottomSheet(context, step, canEdit);
          },
          icon: const Icon(Icons.comment),
          label: const Text("Activity, Comments & Attachments"),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    JobStep step,
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    // Wrapped in RefreshIndicator
    return RefreshIndicator(
      onRefresh: controller.refreshStepData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 160),
        child: StepInfoSection(
          step: step,
          canEdit: canEdit,
          isLoading: isLoading,
        ),
      ),
    );
  }

  Widget _buildSplitLayout(
    JobStep step,
    bool canEdit,
    bool isLoading,
    StepDetailController controller,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          // Wrapped in RefreshIndicator
          child: RefreshIndicator(
            onRefresh: controller.refreshStepData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: StepInfoSection(
                step: step,
                canEdit: canEdit,
                isLoading: isLoading,
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: TimelineBottomSheet(step: step, canEdit: canEdit),
          ),
        ),
      ],
    );
  }

  void _showCommentsBottomSheet(
    BuildContext context,
    JobStep step,
    bool canEdit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TimelineBottomSheet(
                        step: step,
                        canEdit: canEdit,
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// =========================================================================
// WIDGET: The Bottom Sheet Content
// =========================================================================
class TimelineBottomSheet extends ConsumerStatefulWidget {
  final JobStep step;
  final bool canEdit;
  final ScrollController? scrollController;

  const TimelineBottomSheet({
    super.key,
    required this.step,
    required this.canEdit,
    this.scrollController,
  });

  @override
  ConsumerState<TimelineBottomSheet> createState() =>
      _TimelineBottomSheetState();
}

class _TimelineBottomSheetState extends ConsumerState<TimelineBottomSheet> {
  final commentController = TextEditingController();

  // UI State for Filters
  bool _isAttachmentOnlyMode = false;
  Set<StepDiscussionType> _selectedFilterTypes = {};

  // UI State for Input
  StepDiscussionType _inputType = StepDiscussionType.GENERAL;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(stepTimelineProvider(widget.step.id));
    final controller = ref.read(
      stepDetailControllerProvider(widget.step).notifier,
    );
    final currentWorkerId = ref.read(jobServiceProvider).currentWorkerId;

    Widget buildListContent() {
      return Container(
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
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Text(
                        "No items match your filter. Pull to refresh.",
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_isAttachmentOnlyMode) {
              return RefreshIndicator(
                onRefresh: controller.refreshTimeline,
                child: _buildGalleryView(
                  filteredEvents,
                  widget.scrollController,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.refreshTimeline,
              child: ListView.builder(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTightSpace = constraints.maxHeight < 250;

        if (isTightSpace) {
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAdvancedFilterBar(controller),
                SizedBox(height: 300, child: buildListContent()),
                if (widget.canEdit && !_isAttachmentOnlyMode)
                  _buildInputArea(controller),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildAdvancedFilterBar(controller),
            Expanded(child: buildListContent()),
            if (widget.canEdit && !_isAttachmentOnlyMode)
              _buildInputArea(controller),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilterBar(StepDetailController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showMultiSelectFilterDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFilterTypes.isEmpty
                            ? "All Types"
                            : "${_selectedFilterTypes.length} Selected",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            "Attachments",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: _isAttachmentOnlyMode,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) => setState(() => _isAttachmentOnlyMode = val),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            tooltip: "Refresh Activity",
            onPressed: () => controller.refreshTimeline(),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Filter by Type"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: StepDiscussionType.values
                      .where((e) => e != StepDiscussionType.UNKNOWN)
                      .map((type) {
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: type.color),
                              const SizedBox(width: 8),
                              Text(type.label),
                            ],
                          ),
                          value: _selectedFilterTypes.contains(type),
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                _selectedFilterTypes.add(type);
                              } else {
                                _selectedFilterTypes.remove(type);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedFilterTypes.clear();
                    });
                  },
                  child: const Text("Clear All"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryView(
    List<dynamic> events,
    ScrollController? scrollController,
  ) {
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index] as TimelineEvent;
        final isImage =
            event.fileUrl?.toLowerCase().contains('.jpg') == true ||
            event.fileUrl?.toLowerCase().contains('.jpeg') == true ||
            event.fileUrl?.toLowerCase().contains('.png') == true;

        return InkWell(
          onTap: () async {
            if (event.fileUrl != null) {
              await launchUrl(
                Uri.parse(event.fileUrl!),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: isImage && event.fileUrl != null
                        ? Image.network(event.fileUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.insert_drive_file,
                              size: 48,
                              color: event.discussionType.color,
                            ),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: event.discussionType.color.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.discussionType.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: event.discussionType.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.description ?? event.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(StepDetailController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  "Type: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<StepDiscussionType>(
                    value: _inputType,
                    isDense: true,
                    items: StepDiscussionType.values
                        .where((e) => e != StepDiscussionType.UNKNOWN)
                        .map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.label,
                              style: TextStyle(
                                color: type.color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _inputType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () => _showAttachmentOptions(controller),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
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
                        await controller.addComment(
                          commentController.text,
                          _inputType,
                        );
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
          ],
        ),
      ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> events) {
    return events.where((e) {
      if (e is! TimelineEvent) return false;
      if (_isAttachmentOnlyMode && !e.isAttachment) return false;
      if (_selectedFilterTypes.isNotEmpty &&
          !_selectedFilterTypes.contains(e.discussionType)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showAttachmentOptions(StepDetailController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AttachmentUploadSheet(
          onUpload: (path, type, desc) async {
            await controller.uploadFile(path, type, desc);
            if (mounted) Navigator.pop(context);
          },
        );
      },
    );
  }
}

// =========================================================================
// WIDGET: Attachment Sheet
// =========================================================================
class _AttachmentUploadSheet extends StatefulWidget {
  final Future<void> Function(String, StepDiscussionType, String) onUpload;

  const _AttachmentUploadSheet({required this.onUpload});

  @override
  State<_AttachmentUploadSheet> createState() => _AttachmentUploadSheetState();
}

class _AttachmentUploadSheetState extends State<_AttachmentUploadSheet> {
  final _descController = TextEditingController();
  StepDiscussionType _selectedType = StepDiscussionType.GENERAL;
  String? _selectedPath;
  bool _isUploading = false;

  Future<void> _pickFile(int type) async {
    String? path;
    if (type == 0 || type == 1) {
      final img = await ImagePicker().pickImage(
        source: type == 0 ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
      );
      path = img?.path;
    } else {
      final res = await FilePicker.platform.pickFiles();
      path = res?.files.single.path;
    }

    if (path != null) {
      setState(() => _selectedPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload Attachment",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedPath == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadOption(
                    Icons.camera_alt,
                    Colors.blue,
                    "Camera",
                    () => _pickFile(0),
                  ),
                  _buildUploadOption(
                    Icons.photo_library,
                    Colors.purple,
                    "Gallery",
                    () => _pickFile(1),
                  ),
                  _buildUploadOption(
                    Icons.insert_drive_file,
                    Colors.orange,
                    "File",
                    () => _pickFile(2),
                  ),
                ],
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  _selectedPath!.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isUploading
                      ? null
                      : () => setState(() => _selectedPath = null),
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StepDiscussionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: "Attachment Type",
                border: OutlineInputBorder(),
              ),
              items: StepDiscussionType.values
                  .where((e) => e != StepDiscussionType.UNKNOWN)
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: t.color),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isUploading
                  ? null
                  : (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (_selectedPath == null || _isUploading)
                    ? null
                    : () async {
                        setState(() {
                          _isUploading = true;
                        });
                        try {
                          await widget.onUpload(
                            _selectedPath!,
                            _selectedType,
                            _descController.text,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Upload failed: $e")),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isUploading = false;
                            });
                          }
                        }
                      },
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Upload"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 24,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
