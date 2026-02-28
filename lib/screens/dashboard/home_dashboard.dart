import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_screen.dart';
import 'package:mobile_frontend/widgets/filter_bar.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
// Import the new list view
import 'assigned_step_list_view.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  // Helper method to show the menu in a bottom sheet instead of a drawer
  void _showMenuBottomSheet(BuildContext context, WidgetRef ref, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip
          .antiAliasWithSaveLayer, // Ensures the header respects the rounded corners
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wraps content size tightly
            children: [
              UserAccountsDrawerHeader(
                margin: EdgeInsets.zero,
                decoration: const BoxDecoration(color: Colors.black),
                accountName: Text(isAdmin ? "Admin User" : "Worker User"),
                accountEmail: const Text("user@example.com"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    isAdmin ? "A" : "W",
                    style: const TextStyle(fontSize: 24, color: Colors.black),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('My Tasks'),
                selected: true,
                onTap: () => Navigator.pop(context), // Close the bottom sheet
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  ref
                      .read(authNotifierProvider.notifier)
                      .logout(); // Trigger logout
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(assignedStepsFutureProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.role == 'ADMIN';

    return Scaffold(
      // 1. Position the FAB at the bottom left
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // 2. Add the FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuBottomSheet(context, ref, isAdmin),
        backgroundColor: Colors.black, // Match your app branding
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.menu),
      ),

      body: stepsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allSteps) {
          // Wrap your layout builder in a NestedScrollView
          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                // Use SliverAppBar for the floating effect
                SliverAppBar(
                  title: const Text(
                    "My Tasks",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  floating: true, // Appears as soon as you scroll up
                  snap: true, // Snaps fully into view when scrolling up
                  pinned:
                      false, // Scrolls completely out of view when scrolling down
                  backgroundColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor, // Matches app background
                  foregroundColor:
                      Colors.black, // Ensures text and icons are visible
                  elevation: 2, // Gives a slight shadow when floating
                  shadowColor: Colors.black.withOpacity(0.3),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: AppBranding(
                        color: Colors
                            .black, // Changed to black to match the new light app bar
                        size: 24,
                        fontSize: 18,
                      ),
                    ),
                  ],
                  bottom: const PreferredSize(
                    // Adjust this height if your FilterBar is taller or shorter
                    preferredSize: Size.fromHeight(60.0),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: FilterBar(),
                    ),
                  ),
                ),
              ];
            },
            // The body contains your standard Mobile/Tablet layouts
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return const TabletSplitView();
                } else {
                  return const MobileStepListView();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class MobileStepListView extends StatelessWidget {
  const MobileStepListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssignedStepListView();
  }
}

class TabletSplitView extends ConsumerWidget {
  const TabletSplitView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStepId = ref.watch(selectedStepIdProvider);
    final allSteps = ref.watch(assignedStepsFutureProvider).value ?? [];

    Widget detailView;
    if (selectedStepId == null) {
      detailView = const Center(
        child: Text(
          "Select a task to view details.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else {
      final selectedStep = allSteps.firstWhere((s) => s.id == selectedStepId);
      // Reuse StepDetailScreen directly
      detailView = StepDetailScreen(step: selectedStep);
    }

    return Row(
      children: [
        const SizedBox(width: 350, child: AssignedStepListView(isTablet: true)),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(color: Colors.grey[50], child: detailView),
        ),
      ],
    );
  }
}
