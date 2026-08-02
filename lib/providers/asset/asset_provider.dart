import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_frontend/services/network/dio_provider.dart';
import 'package:mobile_frontend/services/asset/asset_service.dart';
import 'package:mobile_frontend/models/asset/asset_model.dart';

final assetServiceProvider = Provider<AssetService>((ref) {
  final dio = ref.watch(dioProvider);
  return AssetService(dio);
});

// Fetches the list of all assigned assets
final assignedAssetsProvider =
    FutureProvider.autoDispose<List<AssetAssignment>>((ref) async {
      return ref.watch(assetServiceProvider).getAssignedAssets();
    });

// A state notifier to handle the loading state of the location update specifically
class AssetLocationUpdater extends StateNotifier<bool> {
  final Ref ref;
  AssetLocationUpdater(this.ref) : super(false); // true when loading

  Future<void> updateLocation(
    int assignmentId,
    Map<String, dynamic> locationPayload,
  ) async {
    state = true; // Set loading
    try {
      await ref
          .read(assetServiceProvider)
          .updateAssetAddress(assignmentId, locationPayload);
      // Refresh the main list to show updated address
      ref.invalidate(assignedAssetsProvider);
    } finally {
      state = false;
    }
  }
}

final assetLocationUpdaterProvider =
    StateNotifierProvider<AssetLocationUpdater, bool>((ref) {
      return AssetLocationUpdater(ref);
    });
