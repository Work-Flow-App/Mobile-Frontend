import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/providers/job/job_provider.dart';
import 'package:mobile_frontend/screens/dashboard/job_steps_screen.dart';
import 'package:mobile_frontend/widgets/filter_bar.dart';
import 'package:mobile_frontend/widgets/floow_logo.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/widgets/app_branding.dart'; 
import 'job_list_view.dart';

class ResponsiveDashboard extends ConsumerWidget {
  const ResponsiveDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allJobsAsync = ref.watch(jobsFutureProvider);
    
    // 1. Get User Role
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Jobs"),
        actions: const [
          // FIX: Pass White color for AppBar usage
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: AppBranding(color: Colors.white, size: 24, fontSize: 18),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
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
              leading: const Icon(Icons.work_outline),
              title: const Text('Jobs'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            
            // 2. Hide Restricted Menu Items for Workers
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Asset Management'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Asset Management (Admin Only)")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); 
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: allJobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allJobs) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return const TabletSplitView();
              } else {
                return const MobileJobListView();
              }
            },
          );
        },
      ),
    );
  }
}

class MobileJobListView extends StatelessWidget {
  const MobileJobListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        FilterBar(),
        Expanded(child: JobListView()),
      ],
    );
  }
}

class TabletSplitView extends ConsumerWidget {
  const TabletSplitView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedJobId = ref.watch(selectedJobIdProvider);
    final allJobs = ref.watch(jobsFutureProvider).value ?? [];

    Widget detailView;
    if (selectedJobId == null) {
      detailView = const Center(
        child: Text(
          "Select a job to view details.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    } else {
      final selectedJob = allJobs.firstWhere((j) => j.id == selectedJobId);
      detailView = JobStepsScreen(job: selectedJob, isEmbedded: true);
    }

    return Row(
      children: [
        const SizedBox(
          width: 350,
          child: Column(
            children: [
              FilterBar(),
              Expanded(child: JobListView(isTablet: true)),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(color: Colors.grey[50], child: detailView),
        ),
      ],
    );
  }
}