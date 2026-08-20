import 'package:flutter/material.dart';

class SyncBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onSyncPressed;

  const SyncBanner({
    super.key,
    this.isOnline = true,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? "Online • Cloud Sync Active" : "Offline Mode • Data saved locally",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onSyncPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 14),
            label: const Text(
              "Sync Now",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
