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
  @override
  Widget build(BuildContext context) {
    final screenState = ref.watch(stepDetailControllerProvider(widget.step));
    final currentStep = screenState.step;
    final canEdit = true; // Based on your auth logic

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCommentsBottomSheet(context, currentStep, canEdit);
        },
        icon: const Icon(Icons.comment),
        label: const Text("Activity, Comments & Attachments"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100), // Space for the FAB
      child: StepInfoSection(
        step: step,
        canEdit: canEdit,
        isLoading: isLoading,
      ),
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
      useSafeArea:
          true, // FIX: Prevents modal from overlapping with top notches on big screens
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

    // Extracted list building logic so we can reuse it cleanly in the LayoutBuilder
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
                    Center(child: Text("No items match your filter.")),
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

    // FIX: LayoutBuilder prevents crash on screen rotation by falling back to scrolling
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTightSpace = constraints.maxHeight < 250;

        if (isTightSpace) {
          return SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAdvancedFilterBar(),
                SizedBox(
                  height: 300, // Fixed height fallback so it doesn't disappear
                  child: buildListContent(),
                ),
                if (widget.canEdit && !_isAttachmentOnlyMode)
                  _buildInputArea(controller),
              ],
            ),
          );
        }

        // Standard layout with Expanded (for portrait / regular screens)
        return Column(
          children: [
            _buildAdvancedFilterBar(),
            Expanded(child: buildListContent()),
            if (widget.canEdit && !_isAttachmentOnlyMode)
              _buildInputArea(controller),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilterBar() {
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
            "Attachments Only",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: _isAttachmentOnlyMode,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) => setState(() => _isAttachmentOnlyMode = val),
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
                    // FIX: Prevent multiline input from growing infinitely and breaking the column
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
          !_selectedFilterTypes.contains(e.discussionType))
        return false;
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
  final Function(String, StepDiscussionType, String) onUpload;
  const _AttachmentUploadSheet({required this.onUpload});

  @override
  State<_AttachmentUploadSheet> createState() => _AttachmentUploadSheetState();
}

class _AttachmentUploadSheetState extends State<_AttachmentUploadSheet> {
  final _descController = TextEditingController();
  StepDiscussionType _selectedType = StepDiscussionType.GENERAL;
  String? _selectedPath;

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
      // FIX: Added SingleChildScrollView so the attachment options and keyboard can scroll
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
                  onPressed: () => setState(() => _selectedPath = null),
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
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
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
                onPressed: _selectedPath == null
                    ? null
                    : () {
                        widget.onUpload(
                          _selectedPath!,
                          _selectedType,
                          _descController.text,
                        );
                      },
                child: const Text("Upload"),
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
      onTap: onTap,
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
