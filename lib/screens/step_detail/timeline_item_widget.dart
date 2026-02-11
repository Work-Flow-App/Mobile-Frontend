import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart';

class TimelineItemWidget extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final int currentWorkerId;

  const TimelineItemWidget({
    super.key,
    required this.event,
    required this.isLast,
    required this.currentWorkerId,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm().format(event.createdAt);
    final displayName = event.actorId == currentWorkerId
        ? "You"
        : "User #${event.actorId}";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatarLine(),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayName, time),
                  const SizedBox(height: 6),
                  if (event.isAttachment)
                    _buildAttachmentContent(context)
                  else
                    _buildCommentContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarLine() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.black54, size: 20),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey[300],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(String name, String time) {
    return Row(
      children: [
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        event.content,
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildAttachmentContent(BuildContext context) {
    final bool hasImage =
        event.fileUrl != null &&
        (event.fileUrl!.toLowerCase().contains('.jpg') ||
            event.fileUrl!.toLowerCase().contains('.jpeg') ||
            event.fileUrl!.toLowerCase().contains('.png'));

    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) _buildImageThumbnail() else _buildFileTile(context),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        event.fileUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[100],
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 100,
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildFileTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.description, color: Theme.of(context).primaryColor),
      title: Text(
        event.content.isNotEmpty ? event.content : "Attachment",
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text(
        "Tap to view",
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Opening ${event.content}...")));
      },
    );
  }
}
