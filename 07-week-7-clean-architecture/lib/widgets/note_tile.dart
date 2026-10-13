import 'package:flutter/material.dart';

import '../data/local/note.dart';

/// Satu baris catatan, dengan badge "belum tersinkron" saat note.dirty == true.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onDelete});

  final Note note;

  /// Dijalankan saat baris ditekan. `null` berarti baris tidak bisa ditekan.
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Row(
        children: [
          if (note.dirty) const DirtyBadge(),
          if (note.dirty) const SizedBox(width: 6),
          Expanded(
            child: Text(
              note.body.isEmpty ? _formatTime(note.updatedAt) : note.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: onTap,
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
    );
  }
}

/// Badge penanda bahwa catatan masih menunggu antrean sync.
///
/// Publik supaya bisa dipakai halaman detail juga — satu konsep, satu widget.
class DirtyBadge extends StatelessWidget {
  const DirtyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'belum tersinkron',
        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.day}/${time.month} ${time.hour}:$minute';
}
