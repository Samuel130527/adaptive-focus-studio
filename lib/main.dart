import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/focus_preset.dart' as db;
import 'models/focus_session.dart';
import 'providers/focus_providers.dart';
import 'screens/settings_screen.dart';
import 'utils/focus_recommendation.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedTheme();
  runApp(const ProviderScope(child: AdaptiveFocusStudio()));
}

class AdaptiveFocusStudio extends StatelessWidget {
  const AdaptiveFocusStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Adaptive Focus Studio',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5267D8),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F7FC),
            cardTheme: const CardThemeData(
              color: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5267D8),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: const CardThemeData(
              color: Color(0xFF242424),
            ),
          ),
          themeMode: mode,
          home: const StudioScreen(),
        );
      },
    );
  }
}

IconData iconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'study':
      return Icons.menu_book_outlined;
    case 'productivity':
      return Icons.psychology_outlined;
    case 'revision':
      return Icons.lightbulb_outline;
    case 'reading':
      return Icons.auto_stories_outlined;
    default:
      return Icons.timer_outlined;
  }
}

class StudioScreen extends ConsumerStatefulWidget {
  const StudioScreen({super.key});

  @override
  ConsumerState<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends ConsumerState<StudioScreen> {
  int _selectedIndex = 0;
  db.FocusPreset? _selectedPreset;
  Timer? _ticker;
  int _defaultFocusMinutes = 25;
  int _dailyGoalMinutes = 120;
  int _remainingSeconds = 25 * 60;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _hasStarted = false;
  bool _hasFinished = false;
  DateTime? _deadline;
  DateTime? _sessionStartedAt;
  bool _seedStarted = false;
  String _historyFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDefaultFocusMinutes();
      await _seedDefaultsIfNeeded();
    });
  }

  Future<void> _loadDefaultFocusMinutes() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      // Read the key used by SettingsScreen; the fallbacks support earlier key names.
      final savedMinutes = preferences.getInt('defaultFocusMinutes') ??
          preferences.getInt('defaultFocusDuration') ??
          preferences.getInt('focusDuration') ??
          preferences.getInt('defaultDuration') ??
          25;

      // Try common key names for the daily goal preference.
      // If your SettingsScreen uses a different key, match it here.
      final savedDailyGoal = preferences.getInt('dailyGoalMinutes') ??
          preferences.getInt('dailyFocusGoal') ??
          preferences.getInt('dailyGoal') ??
          preferences.getInt('dailyTargetMinutes') ??
          120;

      if (!mounted) return;
      setState(() {
        _defaultFocusMinutes = savedMinutes.clamp(5, 120);
        _dailyGoalMinutes = savedDailyGoal.clamp(30, 480);
        if (_selectedPreset == null && !_hasStarted) {
          _remainingSeconds = _defaultFocusMinutes * 60;
        }
      });
    } catch (e) {
      if (mounted) _showMessage('Could not load default focus duration: $e');
    }
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_seedStarted || !mounted) return;
    _seedStarted = true;
    try {
      final existing = await ref.read(focusPresetsProvider.future);
      if (existing.isNotEmpty || !mounted) return;
      final now = DateTime.now().toIso8601String();
      final notifier = ref.read(focusPresetsProvider.notifier);
      for (final item in [
        ('Quick Focus', 'Study', _defaultFocusMinutes, 'A short, focused study block.'),
        ('Deep Work', 'Productivity', 50, 'Longer work without distractions.'),
        ('Short Review', 'Revision', 15, 'Review notes or flashcards.'),
      ]) {
        await notifier.addPreset(db.FocusPreset(
          title: item.$1,
          category: item.$2,
          targetMinutes: item.$3,
          notes: item.$4,
          createdAt: now,
          updatedAt: now,
        ));
      }
    } catch (e) {
      if (mounted) _showMessage('Could not load saved presets: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showPresetForm({db.FocusPreset? preset}) async {
    final editing = preset != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: preset?.title ?? '');
    final categoryController = TextEditingController(text: preset?.category ?? 'Study');
    final notesController = TextEditingController(text: preset?.notes ?? '');
    var duration = preset?.targetMinutes ?? _defaultFocusMinutes;
    var formError = '';

    final result = await showDialog<db.FocusPreset>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editing ? 'Edit preset' : 'Add preset'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: titleController,
                    autofocus: true,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Preset title', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title.' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: categoryController,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a category.' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesController,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: Text('Duration: $duration minutes', style: const TextStyle(fontWeight: FontWeight.w600))),
                  Slider(
                    value: duration.toDouble(), min: 1, max: 120, divisions: 119,
                    label: '$duration min',
                    onChanged: (v) => setDialogState(() => duration = v.round()),
                  ),
                  if (formError.isNotEmpty) Align(alignment: Alignment.centerLeft, child: Text(formError, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final title = titleController.text.trim();
                final category = categoryController.text.trim();
                if (title.length > 40 || category.length > 30 || duration < 1 || duration > 120) {
                  setDialogState(() => formError = 'Check the title, category, and duration.');
                  return;
                }
                final now = DateTime.now().toIso8601String();
                Navigator.pop(dialogContext, db.FocusPreset(
                  id: preset?.id,
                  title: title,
                  category: category,
                  targetMinutes: duration,
                  notes: notesController.text.trim(),
                  createdAt: preset?.createdAt ?? now,
                  updatedAt: now,
                ));
              },
              child: Text(editing ? 'Save changes' : 'Add preset'),
            ),
          ],
        ),
      ),
    );
    // Dispose after the dialog route has completed to avoid disposing controllers
    // while its closing animation is still building.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    titleController.dispose();
    categoryController.dispose();
    notesController.dispose();

    if (result == null || !mounted) return;
    try {
      if (editing) {
        await ref.read(focusPresetsProvider.notifier).updatePreset(result);
        if (_selectedPreset?.id == result.id && !_hasStarted) {
          setState(() {
            _selectedPreset = result;
            _remainingSeconds = result.targetMinutes * 60;
          });
        }
        _showMessage('Preset updated.');
      } else {
        await ref.read(focusPresetsProvider.notifier).addPreset(result);
        _showMessage('Preset added.');
      }
    } catch (e) {
      _showMessage('Could not save preset: $e');
    }
  }

  Future<void> _deletePreset(db.FocusPreset preset) async {
    final confirmed = await _confirm('Delete preset?', 'Delete "${preset.title}"? Existing history will be retained without its preset link.');
    if (!confirmed || !mounted || preset.id == null) return;
    if (_selectedPreset?.id == preset.id && _hasStarted && !_hasFinished) {
      _showMessage('Finish or reset the active session before deleting its preset.');
      return;
    }
    try {
      await ref.read(focusPresetsProvider.notifier).deletePreset(preset.id!);
      if (_selectedPreset?.id == preset.id) {
        setState(() {
          _selectedPreset = null;
          _remainingSeconds = _defaultFocusMinutes * 60;
          _elapsedSeconds = 0;
          _hasStarted = _hasFinished = _isPaused = _isRunning = false;
        });
      }
      _showMessage('Preset deleted.');
    } catch (e) {
      _showMessage('Could not delete preset: $e');
    }
  }

  void _openPreset(db.FocusPreset preset) {
    if (_hasStarted && !_hasFinished) {
      _showMessage('Finish or reset your active session first.');
      return;
    }
    _ticker?.cancel();
    setState(() {
      _selectedPreset = preset;
      _remainingSeconds = preset.targetMinutes * 60;
      _elapsedSeconds = 0;
      _isRunning = _isPaused = _hasStarted = _hasFinished = false;
      _deadline = null;
      _sessionStartedAt = null;
      _selectedIndex = 1;
    });
  }

  void _startTimer() {
    if (_isRunning || _hasFinished || _selectedPreset == null) return;
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _hasStarted = true;
      _sessionStartedAt ??= DateTime.now();
      _deadline = DateTime.now().add(Duration(seconds: _remainingSeconds));
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    if (!mounted || _deadline == null || _selectedPreset == null) return;
    final remaining = _deadline!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      setState(() {
        _remainingSeconds = 0;
        _elapsedSeconds = _selectedPreset!.targetMinutes * 60;
        _isRunning = false;
        _isPaused = false;
      });
      _ticker?.cancel();
      unawaited(_finishSession(completedAutomatically: true));
      return;
    }
    setState(() {
      _remainingSeconds = remaining;
      _elapsedSeconds = (_selectedPreset!.targetMinutes * 60) - remaining;
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
      _deadline = null;
    });
  }

  void _resumeTimer() {
    if (_isPaused && !_hasFinished) _startTimer();
  }

  Future<void> _finishSession({bool completedAutomatically = false}) async {
    final preset = _selectedPreset;
    if (!_hasStarted || _hasFinished || preset == null) {
      if (!_hasStarted) _showMessage('Start a session before finishing it.');
      return;
    }
    _ticker?.cancel();
    final actualSeconds = (preset.targetMinutes * 60 - _remainingSeconds)
        .clamp(0, preset.targetMinutes * 60)
        .toInt();
    final endedAt = DateTime.now();
    final startedAt = _sessionStartedAt ?? endedAt;
    final status = completedAutomatically || _remainingSeconds == 0 ? 'Completed' : 'Finished early';
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _hasFinished = true;
      _elapsedSeconds = actualSeconds;
      _deadline = null;
    });
    try {
      await ref.read(focusSessionsProvider.notifier).addSession(FocusSession(
        presetId: preset.id,
        presetTitle: preset.title,
        startedAt: startedAt.toIso8601String(),
        endedAt: endedAt.toIso8601String(),
        actualSeconds: actualSeconds,
        status: status,
      ));
      _showMessage(status == 'Completed' ? 'Focus session completed and saved!' : 'Your session has been saved.');
    } catch (e) {
      _showMessage('Session ended, but could not save history: $e');
    }
  }

  Future<void> _resetTimer() async {
    if (_hasStarted && !_hasFinished) {
      final shouldReset = await _confirm('Reset session?', 'Your current session will not be added to history.');
      if (!shouldReset) return;
    }
    _ticker?.cancel();
    setState(() {
      _remainingSeconds = (_selectedPreset?.targetMinutes ?? _defaultFocusMinutes) * 60;
      _elapsedSeconds = 0;
      _isRunning = _isPaused = _hasStarted = _hasFinished = false;
      _deadline = null;
      _sessionStartedAt = null;
    });
  }

  Future<void> _showSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );

    // Refresh preferences after the Settings screen closes.
    await _loadDefaultFocusMinutes();
  }

  String _formatTime(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    if (minutes == 0) return '$remainder sec';
    if (remainder == 0) return '$minutes min';
    return '$minutes min $remainder sec';
  }

  Widget _buildHomePage(List<db.FocusPreset> presets, List<FocusSession> sessions) {
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.actualSeconds);

    final now = DateTime.now();
    final todaySessions = sessions.where((session) {
      final startedAt = DateTime.tryParse(session.startedAt)?.toLocal();
      return startedAt != null &&
          startedAt.year == now.year &&
          startedAt.month == now.month &&
          startedAt.day == now.day;
    });
    final todayFocusSeconds = todaySessions.fold<int>(
      0,
      (sum, session) => sum + session.actualSeconds,
    );
    final goalSeconds = _dailyGoalMinutes * 60;
    final goalProgress = goalSeconds == 0
        ? 0.0
        : (todayFocusSeconds / goalSeconds).clamp(0.0, 1.0);

    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Hello, Student!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'Make today a focused day.',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: _SummaryCard(title: 'Sessions', value: '${sessions.length}', icon: Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(title: 'Focus time', value: _formatDuration(totalSeconds), icon: Icons.timer_outlined)),
      ]),
      const SizedBox(height: 14),
      Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined, color: Color(0xFF5267D8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Today's focus goal",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(goalProgress * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF5267D8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goalProgress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE8EBFF),
                  color: const Color(0xFF5267D8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_formatDuration(todayFocusSeconds)} of $_dailyGoalMinutes min',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Text(
                todayFocusSeconds >= goalSeconds
                    ? 'Daily goal reached — great work!'
                    : '${_formatDuration(goalSeconds - todayFocusSeconds)} remaining to reach your goal',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _buildRecommendationCard(sessions),
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Flexible(child: Text('Your focus presets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        TextButton.icon(onPressed: () => _showPresetForm(), icon: const Icon(Icons.add), label: const Text('Add')),
      ]),
      const SizedBox(height: 12),
      if (presets.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No presets yet. Select Add to create your first focus preset.'))),
      for (final preset in presets)
        _PresetCard(
          preset: preset,
          onStart: () => _openPreset(preset),
          onEdit: () => _showPresetForm(preset: preset),
          onDelete: () => _deletePreset(preset),
        ),
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF292D42)
            : const Color(0xFFE8EBFF),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF5267D8)),
            SizedBox(width: 12),
            Expanded(child: Text('Tip: Choose a session duration that fits your study task.')),
          ]),
        ),
      ),
    ]);
  }

  int _recommendedFocusMinutes(List<FocusSession> sessions) {
    return FocusRecommendation.suggestMinutes(
      sessions: sessions,
      defaultMinutes: _defaultFocusMinutes,
    );
  }

  Widget _buildRecommendationCard(List<FocusSession> sessions) {
    final completedCount = sessions
        .where((session) => session.status == 'Completed' && session.actualSeconds > 0)
        .length;
    final recommendation = _recommendedFocusMinutes(sessions);
    final hasHistory = completedCount > 0;

    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF292D42)
          : const Color(0xFFE8EBFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF5267D8)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart focus suggestion',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasHistory
                  ? 'Try $recommendation minutes for your next focus session.'
                  : 'Your suggestion is $_defaultFocusMinutes minutes for now. Complete a session to personalize future suggestions.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasHistory
                  ? 'Reason: this is the average actual duration of your ${completedCount > 5 ? '5 most recent' : 'recent'} completed sessions, rounded to the nearest 5 minutes.'
                  : 'Reason: there are no completed sessions to learn from yet, so the app uses your saved default focus duration.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final presetsState = ref.read(focusPresetsProvider);
                    final existing =
                        presetsState.asData?.value ?? <db.FocusPreset>[];

                    db.FocusPreset? match;
                    for (final preset in existing) {
                      if (preset.targetMinutes == recommendation) {
                        match = preset;
                        break;
                      }
                    }

                    if (match != null) {
                      _openPreset(match);
                      return;
                    }

                    // If no preset has the suggested duration, create one so
                    // Apply always performs a useful action.
                    final now = DateTime.now().toIso8601String();
                    final newPreset = db.FocusPreset(
                      title: 'Smart Focus ($recommendation min)',
                      category: 'Productivity',
                      targetMinutes: recommendation,
                      notes: 'Created from your smart focus suggestion.',
                      createdAt: now,
                      updatedAt: now,
                    );

                    try {
                      await ref
                          .read(focusPresetsProvider.notifier)
                          .addPreset(newPreset);
                      if (!mounted) return;

                      final refreshedState = ref.read(focusPresetsProvider);
                      final refreshedPresets =
                          refreshedState.asData?.value ?? <db.FocusPreset>[];
                      db.FocusPreset? createdPreset;
                      for (final preset in refreshedPresets) {
                        if (preset.title == newPreset.title &&
                            preset.targetMinutes == recommendation) {
                          createdPreset = preset;
                          break;
                        }
                      }

                      if (createdPreset != null) {
                        _openPreset(createdPreset);
                      } else {
                        _showMessage(
                          'Smart Focus preset created. Select it from Your focus presets to begin.',
                        );
                      }
                    } catch (e) {
                      _showMessage('Could not create suggested preset: $e');
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
                OutlinedButton(
                  onPressed: () => _showMessage('No changes made. You can use the suggestion later.'),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusPage() {
    final preset = _selectedPreset;
    if (preset == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer_outlined, size: 54, color: Color(0xFF5267D8)),
        const SizedBox(height: 12),
        const Text('Choose a focus preset to begin.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => setState(() => _selectedIndex = 0), child: const Text('Browse presets')),
      ])));
    }
    final totalSeconds = preset.targetMinutes * 60;
    final progress = totalSeconds == 0 ? 0.0 : _elapsedSeconds / totalSeconds;
    final status = _hasFinished ? 'Session finished' : _isRunning ? 'Stay focused — one task at a time.' : _isPaused ? 'Session paused' : _hasStarted ? 'Ready to resume' : 'Ready when you are';
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Focus Session', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'One task at a time.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 32),
      Card(elevation: 0, color: Theme.of(context).colorScheme.surface, child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        CircleAvatar(radius: 32, backgroundColor: const Color(0xFFE8EBFF), child: Icon(iconForCategory(preset.category), size: 32, color: const Color(0xFF5267D8))),
        const SizedBox(height: 16),
        Text(preset.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          '${preset.category} • ${preset.targetMinutes} minutes',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        SizedBox(width: 220, height: 220, child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 10, backgroundColor: const Color(0xFFE8EBFF), color: const Color(0xFF5267D8), strokeCap: StrokeCap.round),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_formatTime(_remainingSeconds), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'remaining',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ])),
        ])),
        const SizedBox(height: 24),
        Text(status, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
          if (!_isRunning && !_isPaused && !_hasFinished) FilledButton.icon(onPressed: _startTimer, icon: const Icon(Icons.play_arrow), label: Text(_hasStarted ? 'Start focus' : 'Start focus')),
          if (_isRunning) FilledButton.icon(onPressed: _pauseTimer, icon: const Icon(Icons.pause), label: const Text('Pause')),
          if (_isPaused && !_hasFinished) FilledButton.icon(onPressed: _resumeTimer, icon: const Icon(Icons.play_arrow), label: const Text('Resume')),
          if (_hasStarted && !_hasFinished) OutlinedButton.icon(onPressed: () => _finishSession(), icon: const Icon(Icons.check), label: const Text('Finish')),
          OutlinedButton.icon(onPressed: _resetTimer, icon: const Icon(Icons.restart_alt), label: const Text('Reset')),
        ]),
        if (_hasFinished) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: _resetTimer, child: const Text('Start another session')),
        ],
      ]))),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: () {
        if (_hasStarted && !_hasFinished) {
          _showMessage('Finish or reset the active session before leaving it.');
          return;
        }
        setState(() => _selectedIndex = 0);
      }, icon: const Icon(Icons.arrow_back), label: const Text('Choose another preset')),
    ]);
  }

  Widget _buildHistoryPage(List<FocusSession> sessions) {
    final filtered = sessions.where((s) => _historyFilter == 'All' || s.status == _historyFilter).toList();
    final completed = sessions.where((s) => s.status == 'Completed').toList();
    final total = completed.fold<int>(0, (sum, s) => sum + s.actualSeconds);
    final average = completed.isEmpty ? 0 : total ~/ completed.length;

    // Build a local seven-day summary from the saved session history.
    final today = DateTime.now();
    final weekDays = List<DateTime>.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index)),
    );
    final dailySeconds = weekDays.map((day) {
      return sessions.where((session) {
        final startedAt = DateTime.tryParse(session.startedAt)?.toLocal();
        return startedAt != null &&
            startedAt.year == day.year &&
            startedAt.month == day.month &&
            startedAt.day == day.day;
      }).fold<int>(0, (sum, session) => sum + session.actualSeconds);
    }).toList();
    final maxDailySeconds = dailySeconds.fold<int>(0, (maxValue, value) => value > maxValue ? value : maxValue);

    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Session History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(
        'Review your focus sessions.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _SummaryCard(title: 'Sessions', value: '${sessions.length}', icon: Icons.history)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(title: 'Completed avg.', value: _formatDuration(average), icon: Icons.insights_outlined)),
      ]),
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last 7 days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Focus time recorded each day',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(weekDays.length, (index) {
                    final seconds = dailySeconds[index];
                    final barHeight = maxDailySeconds == 0
                        ? 6.0
                        : (seconds / maxDailySeconds * 100).clamp(6.0, 100.0);
                    final day = weekDays[index];
                    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final label = weekdayLabels[day.weekday - 1];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              seconds == 0 ? '0' : '${(seconds / 60).round()}m',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5267D8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(label, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total this week: ${_formatDuration(dailySeconds.fold<int>(0, (sum, value) => sum + value))}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _historyFilter,
        decoration: const InputDecoration(labelText: 'Filter history', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value: 'All', child: Text('All sessions')), DropdownMenuItem(value: 'Completed', child: Text('Completed')), DropdownMenuItem(value: 'Finished early', child: Text('Finished early'))],
        onChanged: (value) { if (value != null) setState(() => _historyFilter = value); },
      ),
      const SizedBox(height: 16),
      if (filtered.isEmpty) Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
        const Icon(Icons.history, size: 48, color: Color(0xFF5267D8)),
        const SizedBox(height: 16),
        const Text('No sessions found', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Complete a focus session and it will appear here.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => setState(() => _selectedIndex = 0), child: const Text('Choose a focus preset')),
      ]))) else for (final record in filtered)
        Card(elevation: 0, color: Theme.of(context).colorScheme.surface, margin: const EdgeInsets.only(bottom: 12), child: ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFFE8EBFF), child: Icon(record.status == 'Completed' ? Icons.check : Icons.timer_outlined, color: const Color(0xFF5267D8))),
          title: Text(record.presetTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${DateTime.tryParse(record.startedAt)?.toLocal().toString().substring(0, 16) ?? record.startedAt}\n${record.status} • ${_formatDuration(record.actualSeconds)}'),
          isThreeLine: true,
        )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(focusPresetsProvider);
    final sessionsAsync = ref.watch(focusSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Focus Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: presetsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load presets: $error'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.read(focusPresetsProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (presets) => sessionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load history: $error'),
              ),
            ),
            data: (sessions) {
              switch (_selectedIndex) {
                case 0:
                  return _buildHomePage(presets, sessions);
                case 1:
                  return _buildFocusPage();
                default:
                  return _buildHistoryPage(sessions);
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (_hasStarted && !_hasFinished && index != 1) {
            _showMessage(
              'Finish or reset your active session before changing tabs.',
            );
            return;
          }
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _SummaryCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Theme.of(context).colorScheme.surface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF5267D8), size: 28),
    const SizedBox(height: 16),
    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ])));
}

class _PresetCard extends StatelessWidget {
  final db.FocusPreset preset;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PresetCard({required this.preset, required this.onStart, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) => Card(elevation: 0, color: Theme.of(context).colorScheme.surface, margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: ListTile(
    contentPadding: const EdgeInsets.only(left: 12, right: 4),
    leading: CircleAvatar(backgroundColor: const Color(0xFFE8EBFF), child: Icon(iconForCategory(preset.category), color: const Color(0xFF5267D8))),
    title: Text(preset.title, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('${preset.category} • ${preset.targetMinutes} minutes${preset.notes.isNotEmpty ? '\n${preset.notes}' : ''}'),
    isThreeLine: preset.notes.isNotEmpty,
    trailing: Wrap(spacing: 0, crossAxisAlignment: WrapCrossAlignment.center, children: [
      IconButton(tooltip: 'Edit preset', onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
      PopupMenuButton<String>(tooltip: 'More options', onSelected: (value) { if (value == 'delete') onDelete(); if (value == 'edit') onEdit(); }, itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
      const SizedBox(width: 4),
      FilledButton(onPressed: onStart, child: const Text('Start')),
    ]),
  )));
}
