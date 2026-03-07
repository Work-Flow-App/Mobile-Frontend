import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/work_log_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_controller.dart';

class WorkLogsSheet extends ConsumerStatefulWidget {
  final JobStep step;
  final bool canEdit;
  final ScrollController? scrollController;

  const WorkLogsSheet({
    super.key,
    required this.step,
    required this.canEdit,
    this.scrollController,
  });

  @override
  ConsumerState<WorkLogsSheet> createState() => _WorkLogsSheetState();
}

class _WorkLogsSheetState extends ConsumerState<WorkLogsSheet> {
  bool _isAddingLog = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _timeIn;
  TimeOfDay? _timeOut;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Helper method to format minutes into "Xh Ym" beautifully
  String _formatDuration(int totalMinutes) {
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Check if Time Out is strictly after Time In
  bool get _isTimeValid {
    if (_timeIn == null || _timeOut == null) return true;
    final inMinutes = _timeIn!.hour * 60 + _timeIn!.minute;
    final outMinutes = _timeOut!.hour * 60 + _timeOut!.minute;
    return outMinutes > inMinutes;
  }

  // Validation getter for enabling the Save button
  bool get _canSave =>
      _selectedDate != null &&
      _timeIn != null &&
      _timeOut != null &&
      _isTimeValid;

  // Format TimeOfDay to API format "HH:mm:ss"
  String _formatTimeForApi(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Future<void> _submitLog() async {
    if (!_canSave) return;

    final controller = ref.read(
      stepDetailControllerProvider(widget.step).notifier,
    );

    try {
      await controller.addWorkLog(
        visitDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        timeIn: _formatTimeForApi(_timeIn!),
        timeOut: _formatTimeForApi(_timeOut!),
        description: _descriptionController.text.trim(),
      );

      // Reset form
      setState(() {
        _isAddingLog = false;
        _selectedDate = null;
        _timeIn = null;
        _timeOut = null;
        _descriptionController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Work log added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(stepWorkLogsProvider(widget.step.id));
    final controller = ref.read(
      stepDetailControllerProvider(widget.step).notifier,
    );

    return RefreshIndicator(
      onRefresh: controller.refreshWorkLogs,
      child: Container(
        color: Colors.grey[50],
        child: CustomScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(),
                  const Divider(height: 1),
                  if (_isAddingLog) _buildAddLogForm(),
                ],
              ),
            ),
            _buildLogsList(logsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Worker Logs",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (widget.canEdit && !_isAddingLog)
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAddingLog = true),
              icon: const Icon(Icons.add),
              label: const Text("Add Log"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddLogForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPickerTile(
                  title: "Date",
                  value: _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : "Select",
                  icon: Icons.calendar_today,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPickerTile(
                  title: "Time In",
                  value: _timeIn != null ? _timeIn!.format(context) : "Select",
                  icon: Icons.access_time,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _timeIn = time);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerTile(
                  title: "Time Out",
                  value: _timeOut != null
                      ? _timeOut!.format(context)
                      : "Select",
                  icon: Icons.access_time_filled,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => _timeOut = time);
                  },
                ),
              ),
            ],
          ),
          if (!_isTimeValid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4.0),
              child: Text(
                "Time Out must be after Time In.",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe the work done (Optional)...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isAddingLog = false),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _canSave ? _submitLog : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                child: const Text("Save Log"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int totalMinutes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.timer, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Text(
            "Total Time Logged",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.blue.shade900,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(totalMinutes),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(AsyncValue<WorkLogResponse> logsAsync) {
    return logsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) =>
          SliverFillRemaining(child: Center(child: Text("Error: $err"))),
      data: (data) {
        final logs = data.visitLogs;

        if (logs.isEmpty && !_isAddingLog) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No work logs found.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              // Show the total summary card as the first item
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildSummaryCard(data.totalWorkedMinutes),
                );
              }
              // Render standard log cards for the rest
              return _buildLogCard(logs[index - 1]);
            }, childCount: logs.length + 1),
          ),
        );
      },
    );
  }

  Widget _buildLogCard(WorkLog log) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  log.visitDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${log.timeIn.substring(0, 5)} - ${log.timeOut.substring(0, 5)}",
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Beautiful display for duration
                    Text(
                      _formatDuration(log.workedMinutes),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (log.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.description,
                style: TextStyle(color: Colors.grey.shade800, height: 1.4),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Logged by #${log.loggedById}",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
