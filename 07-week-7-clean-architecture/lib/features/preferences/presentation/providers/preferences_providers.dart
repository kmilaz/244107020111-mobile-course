import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/repositories/preferences_repository.dart';

// ---------------------------------------------------------------- data layer
final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepositoryImpl(),
);

// -------------------------------------------------------- presentation layer
final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref.watch(preferencesRepositoryProvider).darkMode();
    if (result.failure != null) throw result.failure!;
    return result.value;
  }

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(preferencesRepositoryProvider)
          .setDarkMode(next);
      if (result.failure != null) throw result.failure!;
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) async {
  final result = await ref.watch(preferencesRepositoryProvider).lastOpened();
  if (result.failure != null) throw result.failure!;
  return result.value;
});
