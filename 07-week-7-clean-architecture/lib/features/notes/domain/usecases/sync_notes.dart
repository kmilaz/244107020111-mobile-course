import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Mengirim antrean catatan yang masih `dirty` ke "server".
///
/// Aturan domainnya:
/// 1. kirim **perubahan terlama lebih dulu**, supaya urutan yang diterima
///    server sama dengan urutan user mengubah;
/// 2. tandai bersih **per catatan**, hanya setelah "upload"-nya berhasil —
///    bukan menandai semuanya sekaligus, karena catatan yang gagal akan ikut
///    dianggap terkirim dan tidak pernah dicoba lagi.
///
/// Simulasi upload dipakai karena project ini tidak punya backend tulis. Pada
/// project nyata, ganti `Future.delayed` dengan request sungguhan dan taruh
/// `markSynced` hanya pada respons 2xx.
class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int synced, Failure? failure})> call() async {
    final pending = await _repository.fetchDirty();
    if (pending.failure != null) {
      return (synced: 0, failure: pending.failure);
    }

    var synced = 0;
    for (final note in pending.notes) {
      final id = note.id;
      if (id == null) continue;

      await Future<void>.delayed(const Duration(milliseconds: 300));

      final result = await _repository.markSynced(id);
      if (result.failure != null) continue; // biarkan dirty → dicoba lagi nanti
      synced++;
    }

    return (synced: synced, failure: null);
  }
}
