import 'package:dio/dio.dart';
import 'package:mobile_frontend/models/asset/asset_model.dart';

class AssetService {
  final Dio _dio;

  AssetService(this._dio);

  Future<List<AssetAssignment>> getAssignedAssets() async {
    try {
      final response = await _dio.get('/worker/assets');
      final List data = response.data;
      return data.map((json) => AssetAssignment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load assigned assets: $e');
    }
  }

  Future<AssetAssignment> updateAssetAddress(
    int assignmentId,
    Map<String, dynamic> locationData,
  ) async {
    try {
      final response = await _dio.put(
        '/worker/assets/assignments/$assignmentId/address',
        data: locationData,
      );
      return AssetAssignment.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update asset location: $e');
    }
  }
}
