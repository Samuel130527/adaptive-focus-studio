
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/focus_repository.dart';
import '../models/focus_preset.dart';
import '../models/focus_session.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository();
});

final focusPresetsProvider =
    AsyncNotifierProvider<FocusPresetsNotifier, List<FocusPreset>>(
  FocusPresetsNotifier.new,
);

class FocusPresetsNotifier extends AsyncNotifier<List<FocusPreset>> {
  FocusRepository get _repository => ref.read(focusRepositoryProvider);

  @override
  Future<List<FocusPreset>> build() {
    return _repository.getAllPresets();
  }

  Future<void> addPreset(FocusPreset preset) async {
    await _repository.createPreset(preset);
    state = AsyncData(await _repository.getAllPresets());
  }

  Future<void> updatePreset(FocusPreset preset) async {
    await _repository.updatePreset(preset);
    state = AsyncData(await _repository.getAllPresets());
  }

  Future<void> deletePreset(int id) async {
    await _repository.deletePreset(id);
    state = AsyncData(await _repository.getAllPresets());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getAllPresets);
  }
}

final focusSessionsProvider =
    AsyncNotifierProvider<FocusSessionsNotifier, List<FocusSession>>(
  FocusSessionsNotifier.new,
);

class FocusSessionsNotifier extends AsyncNotifier<List<FocusSession>> {
  FocusRepository get _repository => ref.read(focusRepositoryProvider);

  @override
  Future<List<FocusSession>> build() {
    return _repository.getAllSessions();
  }

  Future<void> addSession(FocusSession session) async {
    await _repository.createSession(session);
    state = AsyncData(await _repository.getAllSessions());
  }

  Future<void> updateSession(FocusSession session) async {
    await _repository.updateSession(session);
    state = AsyncData(await _repository.getAllSessions());
  }

  Future<void> deleteSession(int id) async {
    await _repository.deleteSession(id);
    state = AsyncData(await _repository.getAllSessions());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getAllSessions);
  }
}
