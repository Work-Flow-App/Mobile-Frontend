import 'package:dio/dio.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';
import 'package:mobile_frontend/models/job/work_log_model.dart';

class JobService {
  final Dio _dio;
  // In a real app, you would get this from the AuthProvider state
  final int currentWorkerId = 16879745645878;

  JobService(this._dio);

  // GET /worker/job-workflow-steps
  // GET /worker/job-workflow-steps
  Future<List<JobData>> getAssignedSteps() async {
    try {
      final response = await _dio.get('/worker/job-workflow-steps');
      final List data = response.data;
      return data
          .map((json) => JobData.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      throw Exception('Failed to load assigned steps: $e');
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

  // POST /worker/job-workflow-steps/{id}/ongoing
  Future<void> markStepOngoing(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/ongoing');
    } catch (e) {
      throw Exception('Failed to mark step as ongoing: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/complete-ongoing
  Future<void> completeOngoingStep(int stepId) async {
    try {
      await _dio.post('/worker/job-workflow-steps/$stepId/complete-ongoing');
    } catch (e) {
      throw Exception('Failed to complete ongoing step: $e');
    }
  }

  // POST /worker/job-workflow-steps/{id}/comments [cite: 23]
  Future<void> addComment(
    int stepId,
    String content,
    StepDiscussionType type,
  ) async {
    try {
      await _dio.post(
        '/worker/job-workflow-steps/$stepId/comments',
        data: {
          'content': content,
          'type': type.name, // e.g. "GENERAL"
        },
      );
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> addAttachment(
    int stepId,
    String filePath,
    StepDiscussionType type,
    String? description,
  ) async {
    try {
      String fileName = filePath.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      await _dio.post(
        '/worker/job-workflow-steps/$stepId/attachments',
        queryParameters: {
          'type': type.name,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // GET /worker/job-workflow-steps/{id}/visits
  Future<WorkLogResponse> getWorkLogs(int stepId) async {
    try {
      final response = await _dio.get(
        '/worker/job-workflow-steps/$stepId/visits',
      );
      // Parse the new map response instead of a list
      return WorkLogResponse.fromJson(response.data);
    } catch (e) {
      // Return an empty response object on error to avoid breaking UI
      return WorkLogResponse(visitLogs: [], totalWorkedMinutes: 0);
    }
  }

  // POST /worker/job-workflow-steps/{id}/visits
  Future<void> addWorkLog({
    required int stepId,
    required String visitDate,
    required String timeIn,
    required String timeOut,
    required String description,
  }) async {
    try {
      await _dio.post(
        '/worker/job-workflow-steps/$stepId/visits',
        data: {
          "visitDate": visitDate,
          "timeIn": timeIn,
          "timeOut": timeOut,
          "description": description,
        },
      );
    } catch (e) {
      throw Exception('Failed to add work log: $e');
    }
  }
}
