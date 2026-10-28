
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _durationKey = 'defaultFocusDuration';
  static const _goalKey = 'dailyFocusGoal';
  static const _notificationsKey = 'notificationsEnabled';

  int _duration = 25;
  int _dailyGoal = 120;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _duration = prefs.getInt(_durationKey) ?? 25;
      _dailyGoal = prefs.getInt(_goalKey) ?? 120;
      _notificationsEnabled =
          prefs.getBool(_notificationsKey) ?? true;
      _darkModeEnabled = prefs.getBool(darkModeKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationKey, value);

    if (!mounted) return;
    setState(() => _duration = value);
  }

  Future<void> _saveDailyGoal(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, value);

    if (!mounted) return;
    setState(() => _dailyGoal = value);
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);

    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveDarkMode(bool value) async {
    try {
      await saveTheme(value);

      if (!mounted) return;
      setState(() => _darkModeEnabled = value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the theme preference.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Personalize your focus sessions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your preferences are saved automatically on this device.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Default focus duration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.timer_outlined),
                    title: Text('Default focus duration'),
                    subtitle: Text(
                      'Choose a duration between 5 and 120 minutes.',
                    ),
                  ),
                  Text(
                    '$_duration minutes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_duration min',
                    onChanged: (value) {
                      setState(() => _duration = value.round());
                    },
                    onChangeEnd: (value) {
                      _saveDuration(value.round());
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Daily focus goal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Daily focus goal'),
                    subtitle: Text(
                      'Set your target focus time per day.',
                    ),
                  ),
                  Text(
                    '${_dailyGoal ~/ 60} hr ${_dailyGoal % 60} min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _dailyGoal.toDouble(),
                    min: 30,
                    max: 480,
                    divisions: 15,
                    label: '$_dailyGoal min',
                    onChanged: (value) {
                      setState(() => _dailyGoal = value.round());
                    },
                    onChangeEnd: (value) {
                      _saveDailyGoal(value.round());
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Notifications
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications enabled'),
              subtitle: const Text(
                'Save your preference for focus reminders.',
              ),
              value: _notificationsEnabled,
              onChanged: _saveNotifications,
            ),
          ),

          const SizedBox(height: 12),

          // Dark mode
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              subtitle: const Text(
                'Use a dark theme throughout the app.',
              ),
              value: _darkModeEnabled,
              onChanged: _saveDarkMode,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Local storage'),
              subtitle: Text(
                'Your preferences are stored locally using SharedPreferences.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
