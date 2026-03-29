import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/job/map_provider.dart';

class StatusMultiFilter extends ConsumerWidget {
  const StatusMultiFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(mapStatusFilterProvider);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StepStatus.values.length,
        itemBuilder: (context, index) {
          final status = StepStatus.values[index];
          final isSelected = activeFilters.contains(status);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                status.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: status.color,
              backgroundColor: status.backgroundColor,
              checkmarkColor: Colors.white,
              onSelected: (bool selected) {
                final currentFilters = Set<StepStatus>.from(activeFilters);
                if (selected) {
                  currentFilters.add(status);
                } else {
                  currentFilters.remove(status);
                }
                ref.read(mapStatusFilterProvider.notifier).state =
                    currentFilters;
              },
            ),
          );
        },
      ),
    );
  }
}
