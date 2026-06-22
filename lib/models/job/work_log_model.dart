// Wrapper class for the new API response
class WorkLogResponse {
  final List<WorkLog> visitLogs;
  final int totalWorkedMinutes;

  WorkLogResponse({required this.visitLogs, required this.totalWorkedMinutes});

  factory WorkLogResponse.fromJson(Map<String, dynamic> json) {
    return WorkLogResponse(
      visitLogs:
          (json['visitLogs'] as List<dynamic>?)
              ?.map((e) => WorkLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalWorkedMinutes: json['totalWorkedMinutes'] ?? 0,
    );
  }
}

class WorkLog {
  final int id;
  final String visitDate;
  final String timeIn;
  final String timeOut;
  final int workedMinutes; // New field added
  final String description;
  final int loggedById;
  final DateTime createdAt;

  WorkLog({
    required this.id,
    required this.visitDate,
    required this.timeIn,
    required this.timeOut,
    required this.workedMinutes, // New field added
    required this.description,
    required this.loggedById,
    required this.createdAt,
  });

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    return WorkLog(
      id: json['id'],
      visitDate: json['visitDate'],
      timeIn: json['timeIn'],
      timeOut: json['timeOut'],
      workedMinutes: json['workedMinutes'] ?? 0, // Parse the new field
      description: json['description'] ?? '',
      loggedById: json['loggedById'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}
