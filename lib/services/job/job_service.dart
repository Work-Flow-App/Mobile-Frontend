import 'package:dio/dio.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';

class JobService {
  final Dio _dio;
  // In a real app, you would get this from the AuthProvider state
  final int currentWorkerId = 1; // Example ID based on docs [cite: 18]

  JobService(this._dio);

  // GET /worker/job-workflows [cite: 17]
  Future<List<JobWorkflow>> getJobs() async {
    try {
      final response = await _dio.get('/worker/job-workflows');
      final List data = response.data;
      return data.map((json) => JobWorkflow.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load jobs: $e');
    }
  }

  // GET /worker/job-workflow-steps/{id}/discussion
  // This endpoint aggregates comments and attachments
  Future<List<TimelineEvent>> getStepTimeline(int stepId) async {
    try {
      final response = await _dio.get(
        '/worker/job-workflow-steps/$stepId/discussion',
      );
      final List data = response.data; // [cite: 32]
      return data.map((json) => TimelineEvent.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on error to avoid breaking UI, log in real app
      return [];
    }
  }

  // POST /worker/job-workflow-steps/{id}/start
  Future<void> startStep(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/start');
    } catch (e) {
      throw Exception('Failed to start step: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/complete
  Future<void> completeStep(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/complete');
    } catch (e) {
      throw Exception('Failed to complete step: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/comments [cite: 23]
  Future<void> addComment(int stepId, String content) async {
    try {
      await _dio.post(
        '/worker/job-workflow-steps/$stepId/comments',
        data: {'content': content},
      );
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> addAttachment(int stepId, String filePath) async {
    try {
      String fileName = filePath.split('/').last;

      // Create FormData
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          // The API expects multipart/form-data which Dio handles automatically,
          // but specifying the sub-type helps with some backends.
        ),
      });

      await _dio.post(
        '/worker/job-workflow-steps/$stepId/attachments',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
