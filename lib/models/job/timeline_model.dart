enum TimelineItemType { COMMENT, ATTACHMENT, UNKNOWN }

class TimelineEvent {
  final int id;
  final TimelineItemType itemType;
  final String
  content; // Content for comments, filename for attachments sometimes
  final String? fileUrl;
  final int actorId;
  final DateTime createdAt;

  TimelineEvent({
    required this.id,
    required this.itemType,
    required this.content,
    this.fileUrl,
    required this.actorId,
    required this.createdAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    // Parse itemType string to Enum [cite: 32]
    TimelineItemType type;
    switch (json['itemType']) {
      case 'COMMENT':
        type = TimelineItemType.COMMENT;
        break;
      case 'ATTACHMENT':
        type = TimelineItemType.ATTACHMENT;
        break;
      default:
        type = TimelineItemType.UNKNOWN;
    }

    return TimelineEvent(
      id: json['id'] ?? 0,
      itemType: type,
      content: json['content'] ?? "",
      fileUrl: json['fileUrl'],
      actorId: json['actorId'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? "") ?? DateTime.now(),
    );
  }

  bool get isAttachment => itemType == TimelineItemType.ATTACHMENT;
}
