import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/map_provider.dart';

class StatusMultiFilter extends ConsumerWidget {
  const StatusMultiFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(mapStatusFilterProvider);

    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip is active when the set is empty
          _buildFilterChip(context, ref, "All", activeFilters.isEmpty),

          // Map out the rest of the statuses
          ...StepStatus.values.map((status) {
            return _buildEnumChip(context, ref, status, activeFilters);
          }),
        ],
      ),
    );
  }

  Widget _buildEnumChip(
    BuildContext context,
    WidgetRef ref,
    StepStatus status,
    Set<StepStatus> activeFilters,
  ) {
    final isSelected = activeFilters.contains(status);

    return Padding(
      padding: const EdgeInsets.only(right: 6.0, top: 4, bottom: 4),
      child: FilterChip(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        label: Text(status.label),
        selected: isSelected,
        onSelected: (bool selected) {
          final currentFilters = Set<StepStatus>.from(activeFilters);
          if (selected) {
            currentFilters.add(status);
          } else {
            currentFilters.remove(status);
          }
          ref.read(mapStatusFilterProvider.notifier).state = currentFilters;
        },
        selectedColor: status.backgroundColor.withOpacity(0.20),
        backgroundColor: Colors.white,
        checkmarkColor: status.color,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? status.color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected ? status.color : Colors.grey.shade300,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        showCheckmark: false, // Matches the Home Dashboard design
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0, top: 4, bottom: 4),
      child: FilterChip(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          // Selecting "All" clears the active filters set
          ref.read(mapStatusFilterProvider.notifier).state = {};
        },
        selectedColor: Colors.black,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 1.0),
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        showCheckmark: false,
      ),
    );
  }
}
