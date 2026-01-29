import 'package:dio/dio.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';

class JobService {
  final Dio _dio;
  // In a real app, fetch this from User Profile / Auth Token logic
  final int currentWorkerId = 5; // Updated to match API examples [cite: 2]

  JobService(this._dio);

  // GET /worker/job-workflows [cite: 1]
  Future<List<JobWorkflow>> getJobs() async {
    try {
      final response = await _dio.get('/worker/job-workflows');
      final List data = response.data;
      return data.map((json) => JobWorkflow.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load jobs: $e');
    }
  }

  // GET /worker/job-workflow-steps/{id}/discussion [cite: 11]
  Future<List<TimelineEvent>> getStepTimeline(int stepId) async {
    try {
      final response = await _dio.get(
        '/worker/job-workflow-steps/$stepId/discussion',
      );
      final List data = response.data; // Array of objects [cite: 12]
      return data.map((json) => TimelineEvent.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on error or allow UI to handle
      return [];
    }
  }

  // POST /worker/job-workflow-steps/{id}/start [cite: 3]
  Future<void> startStep(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/start');
    } catch (e) {
      throw Exception('Failed to start step: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/complete [cite: 5]
  Future<void> completeStep(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/complete');
    } catch (e) {
      throw Exception('Failed to complete step: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/comments [cite: 7]
  Future<TimelineEvent> addComment(int stepId, String content) async {
    try {
      final response = await _dio.post(
        '/worker/job-workflow-steps/$stepId/comments',
        data: {'content': content},
      );
      // The API returns the created comment object [cite: 8]
      // We manually add the missing itemType for parsing or construct explicitly
      Map<String, dynamic> data = response.data;
      data['itemType'] = 'COMMENT'; // Ensure consistency for parsing
      return TimelineEvent.fromJson(data);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/attachments [cite: 9]
  Future<TimelineEvent> addAttachment(int stepId, String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/worker/job-workflow-steps/$stepId/attachments',
        data: formData,
      );

      // The API returns the created attachment object [cite: 10]
      Map<String, dynamic> data = response.data;
      data['itemType'] = 'ATTACHMENT';
      return TimelineEvent.fromJson(data);
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }
}
