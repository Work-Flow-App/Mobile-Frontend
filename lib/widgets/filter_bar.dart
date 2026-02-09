import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(stepStatusFilterProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(context, ref, "All", null, currentFilter == null),
          // Iterate over the specific enum order you prefer
          _buildEnumChip(context, ref, StepStatus.INITIATED, currentFilter),
          _buildEnumChip(context, ref, StepStatus.PENDING, currentFilter),
          _buildEnumChip(context, ref, StepStatus.ONGOING, currentFilter),
          _buildEnumChip(context, ref, StepStatus.STARTED, currentFilter),
          _buildEnumChip(context, ref, StepStatus.COMPLETED, currentFilter),
          _buildEnumChip(context, ref, StepStatus.SKIPPED, currentFilter),
        ],
      ),
    );
  }

  Widget _buildEnumChip(
    BuildContext context,
    WidgetRef ref,
    StepStatus status,
    StepStatus? currentFilter,
  ) {
    final isSelected = currentFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
      child: FilterChip(
        label: Text(status.label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(stepStatusFilterProvider.notifier).state = status;
          ref.read(selectedStepIdProvider.notifier).state = null;
        },
        selectedColor: status.backgroundColor.withOpacity(1.0),
        backgroundColor: Colors.white,
        checkmarkColor: status.color,
        labelStyle: TextStyle(
          color: isSelected ? status.color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected ? status.color : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    StepStatus? status,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 12, bottom: 12),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(stepStatusFilterProvider.notifier).state = status;
          ref.read(selectedStepIdProvider.notifier).state = null;
        },
        selectedColor: Colors.black,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}
