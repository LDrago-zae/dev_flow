import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/time_entry_model.dart';

class TimeTrackerService {
  static final TimeTrackerService _instance = TimeTrackerService._internal();
  factory TimeTrackerService() => _instance;
  TimeTrackerService._internal();

  final _supabase = Supabase.instance.client;

  TimeEntry? _activeEntry;
  Timer? _timer;
  int _elapsedSeconds = 0;

  final _timerController = StreamController<int>.broadcast();
  Stream<int> get timerStream => _timerController.stream;

  TimeEntry? get activeEntry => _activeEntry;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isTracking =>
      _activeEntry != null && _activeEntry!.status == 'active';

  /// Start tracking time for a task or project
  Future<TimeEntry?> startTracking({String? taskId, String? projectId}) async {
    try {
      // Stop any existing timer first
      if (_activeEntry != null) {
        await stopTracking();
      }

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final entryData = {
        'user_id': user.id,
        'task_id': taskId,
        'project_id': projectId,
        'start_time': now.toIso8601String(),
        'duration_seconds': 0,
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('time_entries')
          .insert(entryData)
          .select()
          .single();

      _activeEntry = TimeEntry.fromJson(response);
      _elapsedSeconds = 0;
      _startTimer();

      return _activeEntry;
    } catch (e) {
      print('Error starting time tracking: $e');
      return null;
    }
  }

  /// Stop tracking and save the entry
  Future<TimeEntry?> stopTracking() async {
    try {
      if (_activeEntry == null) return null;

      _stopTimer();

      final now = DateTime.now();
      final updatedData = {
        'end_time': now.toIso8601String(),
        'duration_seconds': _elapsedSeconds,
        'status': 'completed',
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('time_entries')
          .update(updatedData)
          .eq('id', _activeEntry!.id)
          .select()
          .single();

      final completedEntry = TimeEntry.fromJson(response);
      _activeEntry = null;
      _elapsedSeconds = 0;
      _timerController.add(0);

      return completedEntry;
    } catch (e) {
      print('Error stopping time tracking: $e');
      return null;
    }
  }

  /// Pause the current tracking session
  Future<void> pauseTracking() async {
    try {
      if (_activeEntry == null || _activeEntry!.status != 'active') return;

      _stopTimer();

      final now = DateTime.now();
      await _supabase
          .from('time_entries')
          .update({
            'duration_seconds': _elapsedSeconds,
            'status': 'paused',
            'updated_at': now.toIso8601String(),
          })
          .eq('id', _activeEntry!.id);

      _activeEntry = _activeEntry!.copyWith(
        status: 'paused',
        durationSeconds: _elapsedSeconds,
      );
    } catch (e) {
      print('Error pausing time tracking: $e');
    }
  }

  /// Resume a paused tracking session
  Future<void> resumeTracking() async {
    try {
      if (_activeEntry == null || _activeEntry!.status != 'paused') return;

      final now = DateTime.now();
      await _supabase
          .from('time_entries')
          .update({'status': 'active', 'updated_at': now.toIso8601String()})
          .eq('id', _activeEntry!.id);

      _activeEntry = _activeEntry!.copyWith(status: 'active');
      _startTimer();
    } catch (e) {
      print('Error resuming time tracking: $e');
    }
  }

  /// Get time entries for a specific task
  Future<List<TimeEntry>> getTaskTimeEntries(String taskId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('time_entries')
          .select()
          .eq('user_id', user.id)
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TimeEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching task time entries: $e');
      return [];
    }
  }

  /// Get time entries for a specific project
  Future<List<TimeEntry>> getProjectTimeEntries(String projectId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('time_entries')
          .select()
          .eq('user_id', user.id)
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TimeEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching project time entries: $e');
      return [];
    }
  }

  /// Get total time spent today
  Future<int> getTodayTotalSeconds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('time_entries')
          .select('duration_seconds')
          .eq('user_id', user.id)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      int total = 0;
      for (final entry in response as List) {
        total += (entry['duration_seconds'] as int? ?? 0);
      }

      // Add current active session time
      if (_activeEntry != null && _activeEntry!.status == 'active') {
        total += _elapsedSeconds;
      }

      return total;
    } catch (e) {
      print('Error fetching today total time: $e');
      return 0;
    }
  }

  /// Restore active session on app restart
  Future<void> restoreActiveSession() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('time_entries')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _activeEntry = TimeEntry.fromJson(response);

        // Calculate elapsed time since start
        final now = DateTime.now();
        final elapsed = now.difference(_activeEntry!.startTime).inSeconds;
        _elapsedSeconds = elapsed + _activeEntry!.durationSeconds;

        _startTimer();
      }
    } catch (e) {
      print('Error restoring active session: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _timerController.add(_elapsedSeconds);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  void dispose() {
    _timer?.cancel();
    _timerController.close();
  }
}
