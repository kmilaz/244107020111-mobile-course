import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_week_5/data/local/note.dart';

void main() {
  test('fromMap tidak meledak kalau kolom hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.id, isNull);
  });
}