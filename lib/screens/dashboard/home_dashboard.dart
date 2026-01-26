import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/widgets/filter_bar.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';
import 'job_list_view.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get User Role
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Jobs"),
        actions: const [
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
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Asset Management'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Asset Management coming soon!"),
                  ),
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
      // 2. Simplified Body: Just FilterBar + List
      body: const Column(
        children: [
          FilterBar(),
          Expanded(child: JobListView()),
        ],
      ),
    );
  }
}
