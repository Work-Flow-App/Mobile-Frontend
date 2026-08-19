import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/providers/asset/asset_provider.dart';
import 'package:mobile_frontend/widgets/asset/asset_card.dart';
import 'package:mobile_frontend/widgets/app_branding.dart';

class AssignedAssetsScreen extends ConsumerWidget {
  const AssignedAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(assignedAssetsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                "My Assigned Assets",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              foregroundColor: Colors.black,
              elevation: innerBoxIsScrolled ? 2 : 0,
              shadowColor: Colors.black.withOpacity(0.3),
              actions: const [
                Padding(
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
        body: assetsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Error loading assets: $error"),
                TextButton(
                  onPressed: () => ref.refresh(assignedAssetsProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
          data: (assets) {
            if (assets.isEmpty) {
              return const Center(
                child: Text(
                  "You have no assigned assets.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(assignedAssetsProvider.future),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 650;

                  if (isTablet) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        // INCREASED: Gave the card more vertical room for SLA & Notes
                        mainAxisExtent: 620,
                      ),
                      itemCount: assets.length,
                      itemBuilder: (context, index) =>
                          // PASSING isGrid: true
                          AssetCard(asset: assets[index], isGrid: true),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: assets.length,
                      itemBuilder: (context, index) =>
                          // PASSING isGrid: false
                          AssetCard(asset: assets[index], isGrid: false),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
