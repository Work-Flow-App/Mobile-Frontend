// lib/models/job/work_log_model.dart
class WorkLog {
  final int id;
  final String visitDate;
  final String timeIn;
  final String timeOut;
  final String description;
  final int loggedById;
  final DateTime createdAt;

  WorkLog({
    required this.id,
    required this.visitDate,
    required this.timeIn,
    required this.timeOut,
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
      description: json['description'],
      loggedById: json['loggedById'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
