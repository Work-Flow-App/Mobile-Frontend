import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/job/timeline_model.dart'; // Ensure this imports your updated model
import 'package:intl/intl.dart';

class TimelineItemWidget extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;
  final int currentWorkerId; // Needed to check if "You" posted it

  const TimelineItemWidget({
    super.key,
    required this.event,
    required this.isLast,
    this.currentWorkerId = 1, // Default or passed from parent
  });

  @override
  Widget build(BuildContext context) {
    // FIX 1: Use 'createdAt' instead of 'timestamp'
    final timeAgo = DateFormat.jm().format(event.createdAt);

    // FIX 2: Derive username from 'actorId'
    // In a real app, you would look up the user's name from a provider/cache.
    final displayName = event.actorId == currentWorkerId
        ? "You"
        : "User #${event.actorId}";

    // Check for image extension
    final bool hasImage =
        event.fileUrl != null &&
        (event.fileUrl!.toLowerCase().endsWith('.jpg') ||
            event.fileUrl!.toLowerCase().endsWith('.jpeg') ||
            event.fileUrl!.toLowerCase().endsWith('.png') ||
            event.fileUrl!.toLowerCase().endsWith('.webp'));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- AVATAR & LINE ---
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.white24)),
            ],
          ),
          const SizedBox(width: 16),

          // --- CONTENT ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Name + Time)
                  Row(
                    children: [
                      Text(
                        displayName, // Fixed Name
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Body (Attachment vs Text)
                  if (event.isAttachment)
                    _buildAttachmentView(hasImage)
                  else
                    Text(
                      event.content,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentView(bool hasImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Uploaded an attachment:",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event.fileUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: Colors.white54,
                        size: 40,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "File",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
        ),
        if (!hasImage) ...[
          const SizedBox(height: 4),
          Text(
            event.content,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ],
    );
  }
}
