class TimelineEvent {
  final int id;
  final String username; // Mapped from 'actorId' or separate logic if needed
  final DateTime timestamp;
  final String content;
  final bool isAttachment;
  final String? fileUrl;

  TimelineEvent({
    required this.id,
    required this.username,
    required this.timestamp,
    required this.content,
    this.isAttachment = false,
    this.fileUrl,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    // API returns 'itemType' as 'COMMENT' or 'ATTACHMENT' [cite: 12]
    final isAttach = json['itemType'] == 'ATTACHMENT';

    return TimelineEvent(
      id: json['id'] ?? 0,
      // API returns actorId. In a real app, you'd map ID to a Name via another call.
      // For now, we mock the name based on actorId for display purposes.
      username: json['actorId'] == 2 ? "Manager" : "Worker",
      timestamp: DateTime.parse(json['createdAt']),
      content: json['content'] ?? "",
      isAttachment: isAttach,
      fileUrl: json['fileUrl'],
    );
  }
}
