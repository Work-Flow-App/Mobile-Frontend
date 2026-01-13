class TimelineEvent {
  final String username;
  final DateTime timestamp;
  final String content;
  final bool isAttachment;

  TimelineEvent({
    required this.username,
    required this.timestamp,
    required this.content,
    this.isAttachment = false,
  });
}
